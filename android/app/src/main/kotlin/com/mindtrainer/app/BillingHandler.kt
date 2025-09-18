package com.mindtrainer.app

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.ConcurrentHashMap

/**
 * Timeout and retry constants for billing operations
 * These values match the Dart-side timeout configuration in lib/foundation/timeouts.dart
 */
private const val BACKOFF_MIN_MS = 200L
private const val BACKOFF_MAX_MS = 5000L
private const val CONNECT_TIMEOUT_MS = 6000L
private const val RESTORE_TIMEOUT_MS = 8000L
private const val PURCHASE_FLOW_GUARD_MS = 15000L

/**
 * Handles Google Play Billing operations for MindTrainer
 * Implements the platform channel interface for Flutter communication
 * 
 * This is a skeleton implementation that will be expanded with real
 * Google Play Billing SDK integration in production builds.
 */
/**
 * Mock ProductDetails structure for development
 * In production, this would be replaced with actual Google Play ProductDetails
 */
data class MockProductDetails(
    val productId: String,
    val title: String,
    val description: String,
    val priceMicros: Long,
    val formattedPrice: String,
    val currencyCode: String,
    val subscriptionPeriod: String,
    val introductoryPrice: String? = null,
    val introductoryPricePeriod: String? = null
)

class BillingHandler(private val activity: Activity) : MethodCallHandler {
    
    // ProductDetails cache for price backfill
    private val detailsCache = ConcurrentHashMap<String, MockProductDetails>()
    
    // Typed event helpers to prevent Map inference errors
    private fun anyMapOf(vararg pairs: Pair<String, Any?>): HashMap<String, Any?> {
        // Forces HashMap<String, Any?> so Kotlin never infers Comparable & Serializable
        return hashMapOf(*pairs)
    }
    
    // Normalize common numeric types for Flutter channel compatibility
    private fun asChannelNumber(value: Number?): Any? {
        if (value == null) return null
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Short -> value.toLong()
            is Byte -> value.toLong()
            is Double -> value // keep as Double
            is Float -> value.toDouble()
            else -> value.toString() // fallback (should not happen)
        }
    }
    
    // Helper to get price info from ProductDetails cache
    private fun priceInfo(productId: String?): Pair<Long?, String?> {
        if (productId == null) return Pair(null, null)
        val details = detailsCache[productId]
        return if (details != null) {
            Pair(details.priceMicros, details.formattedPrice)
        } else {
            Pair(null, null)
        }
    }
    
    // Calculate exponential backoff delay (mirrors Dart RetryPolicy)
    private fun calculateBackoffMs(attemptNumber: Int): Long {
        if (attemptNumber < 0) return 0L
        val exponentialMs = BACKOFF_MIN_MS * (1L shl attemptNumber)
        return if (exponentialMs > BACKOFF_MAX_MS) BACKOFF_MAX_MS else exponentialMs
    }
    
    // Standard purchase payload (adjust fields to match your existing schema)
    private fun buildPurchasePayload(
        productId: String?,
        purchaseToken: String?,
        acknowledged: Boolean?,
        autoRenewing: Boolean?,
        priceMicros: Number?,      // normalize to Long
        priceDisplay: String?,
        originalJson: String?,
        orderId: String? = null,
        purchaseTimeMs: Number? = null, // normalize to Long
        purchaseState: Number? = null,
        obfuscatedAccountId: String? = null,
        developerPayload: String? = null,
        origin: String? = null
    ): HashMap<String, Any?> {
        return anyMapOf(
            "productId" to productId,
            "purchaseToken" to purchaseToken,
            "acknowledged" to acknowledged,
            "autoRenewing" to autoRenewing,
            "priceMicros" to asChannelNumber(priceMicros),
            "price" to priceDisplay,
            "originalJson" to originalJson,
            "orderId" to orderId,
            "purchaseTime" to asChannelNumber(purchaseTimeMs),
            "purchaseState" to asChannelNumber(purchaseState),
            "obfuscatedAccountId" to obfuscatedAccountId,
            "developerPayload" to developerPayload,
            "origin" to origin
        )
    }
    
    // Standard product payload
    private fun buildProductPayload(
        productId: String?,
        title: String?,
        description: String?,
        price: String?,
        priceAmountMicros: Number?,
        priceCurrencyCode: String?,
        subscriptionPeriod: String?,
        introductoryPrice: String? = null,
        introductoryPricePeriod: String? = null
    ): HashMap<String, Any?> {
        return anyMapOf(
            "productId" to productId,
            "title" to title,
            "description" to description,
            "price" to price,
            "priceAmountMicros" to asChannelNumber(priceAmountMicros),
            "priceCurrencyCode" to priceCurrencyCode,
            "subscriptionPeriod" to subscriptionPeriod,
            "introductoryPrice" to introductoryPrice,
            "introductoryPricePeriod" to introductoryPricePeriod
        )
    }
    
    // Single, typed path to invoke events on the channel
    private fun sendEvent(name: String, data: Any? = null) {
        methodChannel?.invokeMethod(name, data)
    }
    
    // Emit purchase event with price backfill from cache
    private fun emitPurchaseEvent(purchase: HashMap<String, Any?>, origin: String) {
        val productId = purchase["productId"] as? String
        val (priceMicros, formattedPrice) = priceInfo(productId)
        
        // Create enriched purchase payload with price data
        val enrichedPurchase = HashMap(purchase)
        if (priceMicros != null && enrichedPurchase["priceMicros"] == null) {
            enrichedPurchase["priceMicros"] = priceMicros
        }
        if (formattedPrice != null && enrichedPurchase["price"] == null) {
            enrichedPurchase["price"] = formattedPrice
        }
        enrichedPurchase["origin"] = origin
        
        sendEvent("onPurchasesUpdated", listOf(enrichedPurchase))
    }
    
    // Standard response payload for billing operations
    private fun buildBillingResponse(
        responseCode: Int,
        debugMessage: String? = null,
        extraData: Map<String, Any?> = emptyMap()
    ): HashMap<String, Any?> {
        val base = anyMapOf(
            "responseCode" to responseCode,
            "debugMessage" to debugMessage
        )
        return HashMap(base + extraData)
    }
    
    // Convenience wrappers for success/failure responses
    private fun sendOk(name: String, message: String? = null, extra: Map<String, Any?> = emptyMap()) {
        val response = buildBillingResponse(BILLING_RESPONSE_RESULT_OK, message, extra)
        sendEvent(name, response)
    }
    
    private fun sendErr(name: String, code: Int, message: String? = null, extra: Map<String, Any?> = emptyMap()) {
        val response = buildBillingResponse(code, message, extra)
        sendEvent(name, response)
    }
    
    companion object {
        const val CHANNEL_NAME = "mindtrainer/billing"
        
        // Billing response codes (matching Google Play Billing)
        const val BILLING_RESPONSE_RESULT_OK = 0
        const val BILLING_RESPONSE_RESULT_USER_CANCELED = 1
        const val BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE = 2
        const val BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE = 3
        const val BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE = 6
        const val BILLING_RESPONSE_RESULT_DEVELOPER_ERROR = 7
        const val BILLING_RESPONSE_RESULT_ERROR = 8
        const val BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED = 5
    }
    
    private var methodChannel: MethodChannel? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)
    
    // Initialize ProductDetails cache with mock data for development
    private fun initializeMockProductDetails() {
        detailsCache["mindtrainer_pro_monthly"] = MockProductDetails(
            productId = "mindtrainer_pro_monthly",
            title = "MindTrainer Pro Monthly",
            description = "Unlock unlimited focus sessions, premium features, and advanced analytics",
            priceMicros = 9990000L,
            formattedPrice = "$9.99",
            currencyCode = "USD",
            subscriptionPeriod = "P1M"
        )
        
        detailsCache["mindtrainer_pro_yearly"] = MockProductDetails(
            productId = "mindtrainer_pro_yearly", 
            title = "MindTrainer Pro Yearly",
            description = "Unlock unlimited focus sessions, premium features, and advanced analytics. Save 20%!",
            priceMicros = 95990000L,
            formattedPrice = "$95.99",
            currencyCode = "USD",
            subscriptionPeriod = "P1Y",
            introductoryPrice = "$47.99",
            introductoryPricePeriod = "P1M"
        )
    }
    
    // Generate mock products from cache for getAvailableProducts
    private fun getMockProducts(): List<HashMap<String, Any?>> {
        return detailsCache.values.map { details ->
            buildProductPayload(
                productId = details.productId,
                title = details.title,
                description = details.description,
                price = details.formattedPrice,
                priceAmountMicros = details.priceMicros,
                priceCurrencyCode = details.currencyCode,
                subscriptionPeriod = details.subscriptionPeriod,
                introductoryPrice = details.introductoryPrice,
                introductoryPricePeriod = details.introductoryPricePeriod
            )
        }
    }
    
    private var mockPurchases = mutableListOf<HashMap<String, Any?>>()
    private var isConnected = false
    
    fun setMethodChannel(channel: MethodChannel) {
        methodChannel = channel
    }
    
    // Warm ProductDetails cache with specified product IDs
    private fun warmProducts(productIds: List<String>) {
        // In production, this would query ProductDetails from Google Play
        // For now, ensure our mock cache is initialized
        if (detailsCache.isEmpty()) {
            initializeMockProductDetails()
        }
        
        // Filter to only the requested product IDs that exist in our mock data
        val availableIds = productIds.filter { detailsCache.containsKey(it) }
        
        // In a real implementation, we would:
        // 1. Create QueryProductDetailsParams for SUBS type
        // 2. Call billingClient.queryProductDetailsAsync
        // 3. Store results in detailsCache
        
        // For mock implementation, products are already in cache
        println("Warmed ${availableIds.size} products: $availableIds")
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        coroutineScope.launch {
            try {
                when (call.method) {
                    "initialize" -> initialize(result)
                    "startConnection" -> startConnection(result)
                    "endConnection" -> endConnection(result)
                    "queryProductDetails" -> queryProductDetails(call, result)
                    "getAvailableProducts" -> getAvailableProducts(result)
                    "launchBillingFlow" -> launchBillingFlow(call, result)
                    "startPurchase" -> startPurchase(call, result)
                    "queryPurchases" -> queryPurchases(result)
                    "getCurrentPurchases" -> getCurrentPurchases(result)
                    "acknowledgePurchase" -> acknowledgePurchase(call, result)
                    "warmProducts" -> warmProductsMethod(call, result)
                    "changeSubscription" -> changeSubscription(call, result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("BILLING_ERROR", e.message, null)
            }
        }
    }
    
    private fun initialize(result: Result) {
        // TODO: Initialize Google Play Billing SDK
        // For now, simulate successful initialization
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_OK,
            debugMessage = "Billing initialized (mock)"
        ))
    }
    
    private fun startConnection(result: Result) {
        // TODO: Connect to Google Play Billing service
        // For now, simulate successful connection
        isConnected = true
        
        // Warm ProductDetails cache after successful connection
        warmProducts(listOf("mindtrainer_pro_monthly", "mindtrainer_pro_yearly"))
        
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_OK,
            debugMessage = "Connected to billing service (mock)"
        ))
    }
    
    private fun endConnection(result: Result) {
        // TODO: Disconnect from Google Play Billing service
        isConnected = false
        mockPurchases.clear()
        result.success(null)
    }
    
    private fun queryProductDetails(call: MethodCall, result: Result) {
        if (!isConnected) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
                debugMessage = "Billing service not connected"
            ))
            return
        }
        
        // TODO: Query real product details from Google Play
        // For now, warm cache with requested product IDs
        val productIds = call.argument<List<String>>("productIds") ?: emptyList()
        warmProducts(productIds)
        
        val availableCount = productIds.count { detailsCache.containsKey(it) }
        
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_OK,
            debugMessage = "Products queried (mock): $availableCount found"
        ))
    }
    
    private fun getAvailableProducts(result: Result) {
        // TODO: Return real queried products from Google Play Billing
        // For now, return products from cache
        result.success(getMockProducts())
    }
    
    private fun warmProductsMethod(call: MethodCall, result: Result) {
        val productIds = call.argument<List<String>>("productIds") ?: listOf("mindtrainer_pro_monthly", "mindtrainer_pro_yearly")
        warmProducts(productIds)
        
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_OK,
            debugMessage = "Products warmed: ${productIds.size} requested"
        ))
    }
    
    private fun launchBillingFlow(call: MethodCall, result: Result) {
        if (!isConnected) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
                debugMessage = "Billing service not connected"
            ))
            return
        }
        
        val productId = call.argument<String>("productId")
        if (productId == null) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
                debugMessage = "Product ID is required"
            ))
            return
        }
        
        // TODO: Launch real Google Play billing flow
        // For now, simulate purchase (80% success rate like FakeBillingAdapter)
        val success = (0..9).random() < 8 // 80% success rate
        
        if (success) {
            // Create mock purchase using typed helper with price backfill
            val currentTime = System.currentTimeMillis()
            val (priceMicros, formattedPrice) = priceInfo(productId)
            
            val purchase = buildPurchasePayload(
                productId = productId,
                purchaseToken = "mock_token_${currentTime}_${(1000..9999).random()}",
                acknowledged = false,
                autoRenewing = true,
                priceMicros = priceMicros, // Backfilled from cache
                priceDisplay = formattedPrice, // Backfilled from cache
                originalJson = null, // Not available in mock
                orderId = "mock_order_$currentTime",
                purchaseTimeMs = currentTime,
                purchaseState = 1, // Purchased
                obfuscatedAccountId = "mock_account_${(100000..999999).random()}",
                developerPayload = null,
                origin = "purchase"
            )
            
            mockPurchases.add(purchase)
            
            // Emit purchase event with enriched data
            emitPurchaseEvent(purchase, "purchase")
            
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_OK,
                debugMessage = "Purchase successful (mock)"
            ))
        } else {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_USER_CANCELED,
                debugMessage = "User canceled purchase (mock)"
            ))
        }
    }
    
    private fun startPurchase(call: MethodCall, result: Result) {
        val productId = call.argument<String>("productId")
        if (productId == null) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
                debugMessage = "Product ID is required"
            ))
            return
        }
        
        // Ensure connected (connectIfNeeded would go here in real implementation)
        if (!isConnected) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
                debugMessage = "Billing service not connected"
            ))
            return
        }
        
        // Ensure ProductDetails is available in cache
        if (!detailsCache.containsKey(productId)) {
            // In real implementation, run one-shot queryProductDetailsAsync
            warmProducts(listOf(productId))
            
            if (!detailsCache.containsKey(productId)) {
                result.success(buildBillingResponse(
                    responseCode = BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE,
                    debugMessage = "Product not available: $productId"
                ))
                return
            }
        }
        
        // Check if user already owns this product (simulate ITEM_ALREADY_OWNED)
        val existingPurchase = mockPurchases.find { 
            it["productId"] == productId && it["purchaseState"] == 1
        }
        
        if (existingPurchase != null) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED,
                debugMessage = "User already owns product: $productId"
            ))
            return
        }
        
        // In real implementation, build BillingFlowParams and call launchBillingFlow
        // For mock, simulate various outcomes including PENDING state
        val outcome = (0..99).random()
        
        when {
            outcome < 5 -> {
                // 5% chance of PENDING state
                val currentTime = System.currentTimeMillis()
                val (priceMicros, formattedPrice) = priceInfo(productId)
                
                val pendingPurchase = buildPurchasePayload(
                    productId = productId,
                    purchaseToken = "pending_token_${currentTime}_${(1000..9999).random()}",
                    acknowledged = false,
                    autoRenewing = true,
                    priceMicros = priceMicros,
                    priceDisplay = formattedPrice,
                    originalJson = null,
                    orderId = "pending_order_$currentTime",
                    purchaseTimeMs = currentTime,
                    purchaseState = 0, // PENDING
                    obfuscatedAccountId = "mock_account_${(100000..999999).random()}",
                    developerPayload = null,
                    origin = "purchase"
                )
                
                mockPurchases.add(pendingPurchase)
                emitPurchaseEvent(pendingPurchase, "purchase")
                
                result.success(buildBillingResponse(
                    responseCode = BILLING_RESPONSE_RESULT_OK,
                    debugMessage = "Purchase pending"
                ))
            }
            
            outcome < 75 -> {
                // 70% chance of immediate success
                val currentTime = System.currentTimeMillis()
                val (priceMicros, formattedPrice) = priceInfo(productId)
                
                val purchase = buildPurchasePayload(
                    productId = productId,
                    purchaseToken = "purchase_token_${currentTime}_${(1000..9999).random()}",
                    acknowledged = false,
                    autoRenewing = true,
                    priceMicros = priceMicros,
                    priceDisplay = formattedPrice,
                    originalJson = null,
                    orderId = "order_$currentTime",
                    purchaseTimeMs = currentTime,
                    purchaseState = 1, // PURCHASED
                    obfuscatedAccountId = "mock_account_${(100000..999999).random()}",
                    developerPayload = null,
                    origin = "purchase"
                )
                
                mockPurchases.add(purchase)
                emitPurchaseEvent(purchase, "purchase")
                
                result.success(buildBillingResponse(
                    responseCode = BILLING_RESPONSE_RESULT_OK,
                    debugMessage = "Purchase successful"
                ))
            }
            
            outcome < 85 -> {
                // 10% chance of user cancellation
                result.success(buildBillingResponse(
                    responseCode = BILLING_RESPONSE_RESULT_USER_CANCELED,
                    debugMessage = "User canceled purchase"
                ))
            }
            
            else -> {
                // 15% chance of other errors (service unavailable, etc.)
                val errorCode = when ((0..2).random()) {
                    0 -> BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE
                    1 -> BILLING_RESPONSE_RESULT_ERROR
                    else -> BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE
                }
                
                result.success(buildBillingResponse(
                    responseCode = errorCode,
                    debugMessage = "Purchase failed with error code: $errorCode"
                ))
            }
        }
    }
    
    private fun queryPurchases(result: Result) {
        if (!isConnected) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
                debugMessage = "Billing service not connected"
            ))
            return
        }
        
        // TODO: Query real purchases from Google Play
        // For now, return success (purchases returned via getCurrentPurchases)
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_OK,
            debugMessage = "Purchases queried (mock): ${mockPurchases.size} found"
        ))
    }
    
    private fun getCurrentPurchases(result: Result) {
        // TODO: Return real purchases from Google Play Billing
        // For now, return mock purchases with price backfill
        val enrichedPurchases = mockPurchases.map { purchase ->
            val productId = purchase["productId"] as? String
            val (priceMicros, formattedPrice) = priceInfo(productId)
            
            val enrichedPurchase = HashMap(purchase)
            if (priceMicros != null && enrichedPurchase["priceMicros"] == null) {
                enrichedPurchase["priceMicros"] = priceMicros
            }
            if (formattedPrice != null && enrichedPurchase["price"] == null) {
                enrichedPurchase["price"] = formattedPrice
            }
            // Add origin for restored purchases
            if (enrichedPurchase["origin"] == null) {
                enrichedPurchase["origin"] = "restore"
            }
            
            enrichedPurchase
        }
        
        result.success(enrichedPurchases)
    }
    
    private fun acknowledgePurchase(call: MethodCall, result: Result) {
        if (!isConnected) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_SERVICE_UNAVAILABLE,
                debugMessage = "Billing service not connected"
            ))
            return
        }
        
        val purchaseToken = call.argument<String>("purchaseToken")
        if (purchaseToken == null) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
                debugMessage = "Purchase token is required"
            ))
            return
        }
        
        // TODO: Acknowledge real purchase with Google Play
        // For now, find and update mock purchase
        val purchaseIndex = mockPurchases.indexOfFirst { 
            it["purchaseToken"] == purchaseToken
        }
        
        if (purchaseIndex >= 0) {
            val purchase = HashMap(mockPurchases[purchaseIndex])
            purchase["acknowledged"] = true
            mockPurchases[purchaseIndex] = purchase
            
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_OK,
                debugMessage = "Purchase acknowledged (mock)"
            ))
        } else {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE,
                debugMessage = "Purchase not found"
            ))
        }
    }
    
    private fun changeSubscription(call: MethodCall, result: Result) {
        // This is a placeholder implementation for subscription upgrade/downgrade functionality
        // Currently returns UNIMPLEMENTED until Play Console base plans are configured
        
        val fromProductId = call.argument<String>("fromProductId")
        val toProductId = call.argument<String>("toProductId")
        val prorationMode = call.argument<String>("prorationMode") ?: "IMMEDIATE_WITH_TIME_PRORATION"
        
        if (fromProductId == null || toProductId == null) {
            result.success(buildBillingResponse(
                responseCode = BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
                debugMessage = "Both fromProductId and toProductId are required"
            ))
            return
        }
        
        // Log the parameters for verification during testing
        println("changeSubscription called: $fromProductId -> $toProductId (proration: $prorationMode)")
        
        // TODO: In the future, implement real subscription change logic:
        // 1. Find existing subscription purchase
        // 2. Create BillingFlowParams with SubscriptionUpdateParams
        // 3. Set old purchase token and proration mode
        // 4. Launch billing flow with update params
        
        // For now, return UNIMPLEMENTED as specified
        result.success(buildBillingResponse(
            responseCode = BILLING_RESPONSE_RESULT_DEVELOPER_ERROR,
            debugMessage = "UNIMPLEMENTED: Subscription changes require Play Console base plan configuration"
        ))
    }
    
    fun dispose() {
        methodChannel = null
        mockPurchases.clear()
        isConnected = false
    }
}