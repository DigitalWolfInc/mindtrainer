/// Centralized billing constants and string management
/// 
/// This file contains all constants, strings, and configuration values
/// used across the billing system to ensure consistency and easy maintenance.

/// Billing platform channels
class BillingChannels {
  static const String main = 'mindtrainer/billing';
  static const String fake = 'mindtrainer/billing/fake';
  
  // Prevent instantiation
  BillingChannels._();
}

/// Google Play Billing response codes
/// 
/// These constants match the BillingClient.BillingResponseCode values
/// from the Google Play Billing Library.
class BillingResponseCodes {
  static const int ok = 0;
  static const int userCanceled = 1;
  static const int serviceUnavailable = 2;
  static const int billingUnavailable = 3;
  static const int itemUnavailable = 6;
  static const int itemAlreadyOwned = 5;
  static const int developerError = 7;
  static const int error = 8;
  
  // Prevent instantiation
  BillingResponseCodes._();
}

/// Purchase states from Google Play Billing
class PurchaseStates {
  static const int pending = 0;
  static const int purchased = 1;
  static const int canceled = 2;
  
  // Prevent instantiation
  PurchaseStates._();
}

/// Product IDs for all subscription products
/// 
/// These must match the product IDs configured in Google Play Console.
class ProductIds {
  static const String proMonthly = 'mindtrainer_pro_monthly';
  static const String proYearly = 'mindtrainer_pro_yearly';
  
  static const List<String> allSubscriptions = [
    proMonthly,
    proYearly,
  ];
  
  /// Check if a product ID is a Pro subscription
  static bool isProProduct(String productId) {
    return allSubscriptions.contains(productId);
  }
  
  // Prevent instantiation
  ProductIds._();
}

/// Legacy product ID mapping for backward compatibility
/// 
/// Maps legacy product IDs used by ProCatalog to new standardized IDs.
class LegacyProductMapping {
  static const Map<String, String> legacyToNew = {
    'pro_monthly': ProductIds.proMonthly,
    'pro_yearly': ProductIds.proYearly,
  };
  
  static const Map<String, String> newToLegacy = {
    ProductIds.proMonthly: 'pro_monthly',
    ProductIds.proYearly: 'pro_yearly',
  };
  
  /// Convert legacy product ID to new format
  static String fromLegacy(String legacyId) {
    return legacyToNew[legacyId] ?? legacyId;
  }
  
  /// Convert new product ID to legacy format
  static String toLegacy(String newId) {
    return newToLegacy[newId] ?? newId;
  }
  
  // Prevent instantiation
  LegacyProductMapping._();
}

/// File system constants
class BillingFileConstants {
  static const String receiptsFileName = 'purchase_receipts.json';
  
  // Prevent instantiation
  BillingFileConstants._();
}

/// Error code constants for consistent error handling
class BillingErrorCodes {
  static const String success = 'SUCCESS';
  static const String userCanceled = 'USER_CANCELED';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String billingUnavailable = 'BILLING_UNAVAILABLE';
  static const String itemUnavailable = 'ITEM_UNAVAILABLE';
  static const String developerError = 'DEVELOPER_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String itemAlreadyOwned = 'ITEM_ALREADY_OWNED';
  static const String itemNotOwned = 'ITEM_NOT_OWNED';
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String connectionFailed = 'CONNECTION_FAILED';
  
  // Prevent instantiation
  BillingErrorCodes._();
}

/// User-facing error messages
/// 
/// Provides consistent, user-friendly error messages for all billing errors.
class BillingErrorMessages {
  static const String userCanceled = 'Purchase was canceled.';
  static const String serviceUnavailable = 'Billing service is temporarily unavailable. Please try again later.';
  static const String billingUnavailable = 'In-app purchases are not available on this device.';
  static const String itemUnavailable = 'This subscription is currently unavailable. Please try again later.';
  static const String developerError = 'There was a configuration error. Please contact support.';
  static const String networkError = 'Network connection error. Please check your connection and try again.';
  static const String itemAlreadyOwned = 'You already own this subscription. Try restoring your purchases.';
  static const String itemNotOwned = 'This subscription is not associated with your account.';
  static const String unknownError = 'Purchase failed due to an unexpected error. Please try again.';
  static const String connectionFailed = 'Failed to connect to billing service. Please try again.';
  static const String notConnected = 'Not connected to billing service';
  static const String unknown = 'An unknown error occurred. Please try again.';
  
  /// Get user-friendly error message for error code
  static String forErrorCode(String? errorCode, [String? debugMessage]) {
    if (errorCode == null) {
      return unknown;
    }
    
    switch (errorCode) {
      case BillingErrorCodes.userCanceled:
        return userCanceled;
      case BillingErrorCodes.serviceUnavailable:
        return serviceUnavailable;
      case BillingErrorCodes.billingUnavailable:
        return billingUnavailable;
      case BillingErrorCodes.itemUnavailable:
        return itemUnavailable;
      case BillingErrorCodes.developerError:
        return developerError;
      case BillingErrorCodes.networkError:
        return networkError;
      case BillingErrorCodes.itemAlreadyOwned:
        return itemAlreadyOwned;
      case BillingErrorCodes.itemNotOwned:
        return itemNotOwned;
      case BillingErrorCodes.connectionFailed:
        return connectionFailed;
      default:
        if (debugMessage?.isNotEmpty == true) {
          return 'Purchase failed: $debugMessage';
        }
        return unknownError;
    }
  }
  
  // Prevent instantiation
  BillingErrorMessages._();
}

/// Retry configuration for billing operations
class BillingRetryConfig {
  /// Error codes that should be retried
  static const List<String> retryableErrors = [
    BillingErrorCodes.serviceUnavailable,
    BillingErrorCodes.networkError,
    BillingErrorCodes.itemUnavailable,
    BillingErrorCodes.unknownError,
  ];
  
  /// Error codes that should NOT be retried
  static const List<String> nonRetryableErrors = [
    BillingErrorCodes.userCanceled,
    BillingErrorCodes.billingUnavailable,
    BillingErrorCodes.developerError,
    BillingErrorCodes.itemAlreadyOwned,
  ];
  
  /// Maximum retry delay in seconds
  static const int maxRetryDelaySeconds = 30;
  
  /// Base retry delay in seconds
  static const int baseRetryDelaySeconds = 1;
  
  /// Check if an error code is retryable
  static bool isRetryable(String? errorCode) {
    if (errorCode == null) return true;
    
    if (nonRetryableErrors.contains(errorCode)) {
      return false;
    }
    
    // Default to retryable for unknown errors
    return true;
  }
  
  // Prevent instantiation
  BillingRetryConfig._();
}

/// Debug and logging messages
class BillingDebugMessages {
  // Initialization
  static const String billingInitialized = 'Billing initialized successfully';
  static const String fakeBillingInitialized = 'Fake billing initialized successfully';
  
  // Connection
  static const String connected = 'Connected to billing service';
  static const String fakeConnected = 'Connected to fake billing service';
  static const String connectionFailed = 'Connection failed';
  
  // Product queries
  static const String productsQueried = 'Products queried successfully';
  static const String fakeProductsQueried = 'Products queried successfully (fake)';
  
  // Purchases
  static const String purchaseSuccessful = 'Purchase successful';
  static const String fakePurchaseSuccessful = 'Purchase successful (fake)';
  static const String purchaseFailed = 'Purchase failed';
  static const String userCanceledPurchase = 'User canceled purchase';
  
  // Purchase queries
  static const String purchasesQueried = 'Purchases queried successfully';
  static const String fakePurchasesQueried = 'Purchases queried successfully (fake)';
  
  // Acknowledgments
  static const String purchaseAcknowledged = 'Purchase acknowledged';
  static const String fakePurchaseAcknowledged = 'Purchase acknowledged (fake)';
  static const String purchaseNotFound = 'Purchase not found';
  
  // Pro state
  static const String proStateRestored = 'Pro state restored from receipts';
  static const String proStateUpdated = 'Pro state updated';
  static const String noValidReceipts = 'No valid Pro receipts found';
  
  // Receipt storage
  static const String receiptSaved = 'Receipt saved successfully';
  static const String receiptRestored = 'Receipt restored from storage';
  static const String receiptStorageCleared = 'Receipt storage cleared';
  
  // Prevent instantiation
  BillingDebugMessages._();
}

/// Subscription display names for UI
class SubscriptionDisplayNames {
  static const String monthly = 'Pro Monthly';
  static const String yearly = 'Pro Yearly';
  
  /// Get display name for product ID
  static String forProductId(String productId) {
    switch (productId) {
      case ProductIds.proMonthly:
        return monthly;
      case ProductIds.proYearly:
        return yearly;
      default:
        return 'Unknown Subscription';
    }
  }
  
  // Prevent instantiation
  SubscriptionDisplayNames._();
}

/// Configuration constants for fake billing adapter
class FakeBillingConfig {
  static const double defaultSuccessRate = 0.8;
  static const Duration defaultOperationDelay = Duration(seconds: 1);
  static const bool defaultSimulateNetworkDelays = true;
  
  // Purchase outcome probabilities
  static const double userCancellationRate = 0.1; // 10%
  static const double paymentFailureRate = 0.05;  // 5%
  
  // Fake product data
  static const String fakeMonthlyPrice = '\$9.99';
  static const String fakeYearlyPrice = '\$99.99';
  static const int fakeMonthlyPriceMicros = 9990000;
  static const int fakeYearlyPriceMicros = 99990000;
  static const String fakeCurrencyCode = 'USD';
  static const String fakeMonthlyPeriod = 'P1M';
  static const String fakeYearlyPeriod = 'P1Y';
  
  // Prevent instantiation
  FakeBillingConfig._();
}