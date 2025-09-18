package com.mindtrainer.app

import android.app.Activity
import android.content.Context
import android.util.Log
import com.android.billingclient.api.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Google Play Billing integration for MindTrainer Pro subscriptions
 * 
 * Handles billing operations and communicates with Flutter via method channels.
 * Supports both production and sandbox modes for testing.
 */
class BillingMethodCallHandler(
    private val context: Context,
    private val activity: Activity?,
    private val methodChannel: MethodChannel
) : MethodCallHandler, PurchasesUpdatedListener, BillingClientStateListener {

    companion object {
        private const val TAG = "MindTrainerBilling"
    }

    private var billingClient: BillingClient? = null
    private var isConnected = false
    private var sandboxMode = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startConnection" -> {
                val sandbox = call.argument<Boolean>("sandboxMode") ?: false
                startConnection(sandbox, result)
            }
            "endConnection" -> {
                endConnection(result)
            }
            "queryProducts" -> {
                val productIds = call.argument<List<String>>("productIds") ?: emptyList()
                val productType = call.argument<String>("productType") ?: "subs"
                queryProducts(productIds, productType, result)
            }
            "launchPurchaseFlow" -> {
                val productId = call.argument<String>("productId") ?: ""
                val productType = call.argument<String>("productType") ?: "subs"
                launchPurchaseFlow(productId, productType, result)
            }
            "queryPurchases" -> {
                val productType = call.argument<String>("productType") ?: "subs"
                queryPurchases(productType, result)
            }
            "acknowledgePurchase" -> {
                val purchaseToken = call.argument<String>("purchaseToken") ?: ""
                acknowledgePurchase(purchaseToken, result)
            }
            "isSubscriptionSupported" -> {
                isSubscriptionSupported(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startConnection(sandbox: Boolean, result: Result) {
        if (isConnected) {
            result.success(hashMapOf<String, Any?>(
                "success" to true,
                "responseCode" to 0,
                "debugMessage" to "Already connected"
            ))
            return
        }

        sandboxMode = sandbox
        
        billingClient = BillingClient.newBuilder(context)
            .setListener(this)
            .enablePendingPurchases()
            .build()

        billingClient?.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                Log.d(TAG, "Billing setup finished with response code: ${billingResult.responseCode}")
                
                isConnected = billingResult.responseCode == BillingClient.BillingResponseCode.OK
                
                // Notify Flutter of connection state change
                methodChannel.invokeMethod("onConnectionStateChanged", hashMapOf<String, Any?>(
                    "state" to if (isConnected) 2 else 3 // connected = 2, error = 3
                ))
                
                result.success(hashMapOf<String, Any?>(
                    "success" to isConnected,
                    "responseCode" to billingResult.responseCode,
                    "debugMessage" to billingResult.debugMessage
                ))
            }

            override fun onBillingServiceDisconnected() {
                Log.d(TAG, "Billing service disconnected")
                isConnected = false
                
                // Notify Flutter of disconnection
                methodChannel.invokeMethod("onConnectionStateChanged", hashMapOf<String, Any?>(
                    "state" to 0 // disconnected = 0
                ))
            }
        })
    }

    private fun endConnection(result: Result) {
        billingClient?.endConnection()
        billingClient = null
        isConnected = false
        result.success(null)
    }

    private fun queryProducts(productIds: List<String>, productType: String, result: Result) {
        if (!isConnected || billingClient == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        val productList = productIds.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(
                    if (productType == "subs") BillingClient.ProductType.SUBS
                    else BillingClient.ProductType.INAPP
                )
                .build()
        }

        val queryProductDetailsParams = QueryProductDetailsParams.newBuilder()
            .setProductList(productList)
            .build()

        billingClient?.queryProductDetailsAsync(queryProductDetailsParams) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val products = productDetailsList.map { productDetails ->
                    val subscriptionOffer = productDetails.subscriptionOfferDetails?.firstOrNull()
                    val pricingPhase = subscriptionOffer?.pricingPhases?.pricingPhaseList?.firstOrNull()
                    
                    hashMapOf<String, Any?>(
                        "productId" to productDetails.productId,
                        "type" to productDetails.productType,
                        "title" to productDetails.title,
                        "description" to productDetails.description,
                        "price" to (pricingPhase?.formattedPrice ?: ""),
                        "priceAmountMicros" to (pricingPhase?.priceAmountMicros ?: 0L),
                        "priceCurrencyCode" to (pricingPhase?.priceCurrencyCode ?: "USD")
                    )
                }
                result.success(products)
            } else {
                Log.e(TAG, "Error querying products: ${billingResult.debugMessage}")
                result.success(emptyList<Map<String, Any?>>())
            }
        }
    }

    private fun launchPurchaseFlow(productId: String, productType: String, result: Result) {
        if (!isConnected || billingClient == null || activity == null) {
            result.success(hashMapOf<String, Any?>(
                "success" to false,
                "responseCode" to BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE,
                "debugMessage" to "Billing not connected or no activity"
            ))
            return
        }

        // First query the product details to get the offer token
        val productList = listOf(
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(
                    if (productType == "subs") BillingClient.ProductType.SUBS
                    else BillingClient.ProductType.INAPP
                )
                .build()
        )

        val queryProductDetailsParams = QueryProductDetailsParams.newBuilder()
            .setProductList(productList)
            .build()

        billingClient?.queryProductDetailsAsync(queryProductDetailsParams) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && productDetailsList.isNotEmpty()) {
                val productDetails = productDetailsList.first()
                val subscriptionOffer = productDetails.subscriptionOfferDetails?.firstOrNull()
                
                if (subscriptionOffer != null) {
                    val productDetailsParamsList = listOf(
                        BillingFlowParams.ProductDetailsParams.newBuilder()
                            .setProductDetails(productDetails)
                            .setOfferToken(subscriptionOffer.offerToken)
                            .build()
                    )

                    val billingFlowParams = BillingFlowParams.newBuilder()
                        .setProductDetailsParamsList(productDetailsParamsList)
                        .build()

                    val launchResult = billingClient?.launchBillingFlow(activity, billingFlowParams)
                    
                    result.success(hashMapOf<String, Any?>(
                        "success" to (launchResult?.responseCode == BillingClient.BillingResponseCode.OK),
                        "responseCode" to (launchResult?.responseCode ?: -1),
                        "debugMessage" to (launchResult?.debugMessage ?: "Unknown error")
                    ))
                } else {
                    result.success(hashMapOf<String, Any?>(
                        "success" to false,
                        "responseCode" to BillingClient.BillingResponseCode.ITEM_UNAVAILABLE,
                        "debugMessage" to "No subscription offers available"
                    ))
                }
            } else {
                result.success(hashMapOf<String, Any?>(
                    "success" to false,
                    "responseCode" to billingResult.responseCode,
                    "debugMessage" to billingResult.debugMessage
                ))
            }
        }
    }

    private fun queryPurchases(productType: String, result: Result) {
        if (!isConnected || billingClient == null) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        val queryPurchasesParams = QueryPurchasesParams.newBuilder()
            .setProductType(
                if (productType == "subs") BillingClient.ProductType.SUBS
                else BillingClient.ProductType.INAPP
            )
            .build()

        coroutineScope.launch {
            val purchasesResult = billingClient?.queryPurchasesAsync(queryPurchasesParams)
            
            if (purchasesResult?.billingResult?.responseCode == BillingClient.BillingResponseCode.OK) {
                val purchases = purchasesResult.purchasesList.map { purchase ->
                    hashMapOf<String, Any?>(
                        "purchaseToken" to purchase.purchaseToken,
                        "productId" to purchase.products.firstOrNull().orEmpty(),
                        "state" to when (purchase.purchaseState) {
                            Purchase.PurchaseState.PURCHASED -> 1 // purchased
                            Purchase.PurchaseState.PENDING -> 0   // pending
                            else -> 3 // failed
                        },
                        "purchaseTime" to purchase.purchaseTime,
                        "acknowledged" to purchase.isAcknowledged,
                        "autoRenewing" to purchase.isAutoRenewing
                    )
                }
                result.success(purchases)
            } else {
                Log.e(TAG, "Error querying purchases: ${purchasesResult?.billingResult?.debugMessage}")
                result.success(emptyList<Map<String, Any?>>())
            }
        }
    }

    private fun acknowledgePurchase(purchaseToken: String, result: Result) {
        if (!isConnected || billingClient == null) {
            result.success(hashMapOf<String, Any?>(
                "success" to false,
                "responseCode" to BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE,
                "debugMessage" to "Billing not connected"
            ))
            return
        }

        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchaseToken)
            .build()

        billingClient?.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            result.success(hashMapOf<String, Any?>(
                "success" to (billingResult.responseCode == BillingClient.BillingResponseCode.OK),
                "responseCode" to billingResult.responseCode,
                "debugMessage" to billingResult.debugMessage
            ))
        }
    }

    private fun isSubscriptionSupported(result: Result) {
        if (!isConnected || billingClient == null) {
            result.success(false)
            return
        }

        val billingResult = billingClient?.isFeatureSupported(BillingClient.FeatureType.SUBSCRIPTIONS)
        result.success(billingResult?.responseCode == BillingClient.BillingResponseCode.OK)
    }

    // BillingClientStateListener implementation
    override fun onBillingSetupFinished(billingResult: BillingResult) {
        // Handled in startConnection
    }

    override fun onBillingServiceDisconnected() {
        isConnected = false
        methodChannel.invokeMethod("onConnectionStateChanged", hashMapOf<String, Any?>(
            "state" to 0 // disconnected
        ))
    }

    // PurchasesUpdatedListener implementation
    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
        Log.d(TAG, "Purchases updated with response code: ${billingResult.responseCode}")
        
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            val purchaseList = purchases.map { purchase ->
                hashMapOf<String, Any?>(
                    "purchaseToken" to purchase.purchaseToken,
                    "productId" to purchase.products.firstOrNull().orEmpty(),
                    "state" to when (purchase.purchaseState) {
                        Purchase.PurchaseState.PURCHASED -> 1 // purchased
                        Purchase.PurchaseState.PENDING -> 0   // pending
                        else -> 3 // failed
                    },
                    "purchaseTime" to purchase.purchaseTime,
                    "acknowledged" to purchase.isAcknowledged,
                    "autoRenewing" to purchase.isAutoRenewing
                )
            }
            
            // Notify Flutter of purchase updates
            methodChannel.invokeMethod("onPurchasesUpdated", hashMapOf<String, Any?>(
                "purchases" to purchaseList
            ))
        } else {
            Log.e(TAG, "Purchase failed or was cancelled: ${billingResult.debugMessage}")
            
            // Notify Flutter of empty purchase list (purchase failed/cancelled)
            methodChannel.invokeMethod("onPurchasesUpdated", hashMapOf<String, Any?>(
                "purchases" to emptyList<Map<String, Any?>>()
            ))
        }
    }
}