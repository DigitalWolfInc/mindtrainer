# MindTrainer Billing System

This directory contains the complete billing system implementation for MindTrainer Pro subscriptions, built on Google Play Billing Library integration.

## Architecture Overview

The billing system follows a layered architecture with clear separation of concerns:

```
UI Layer (ProCatalogScreen)
    ↓
Service Layer (BillingService)
    ↓
State Management (ProState) + Platform Channel (BillingChannel)
    ↓
Persistence (ReceiptStore) + Models (BillingResult, ProductInfo, PurchaseInfo)
    ↓
Native Android (BillingHandler.kt)
    ↓
Google Play Billing Library
```

## Core Components

### 1. Platform Channel Integration (`channel.dart`)
- **Purpose**: Direct communication with native Android billing implementation
- **Key Features**:
  - Type-safe method calls to native code
  - Stream-based purchase updates
  - Connection state management
  - Automatic error handling and retry logic

#### Channel Method Contract

The following methods are available on the `mindtrainer/billing` channel:

| Method | Parameters | Return | Description |
|--------|------------|--------|-------------|
| `initialize` | - | `BillingResult` | Initialize the billing client |
| `startConnection` | - | `BillingResult` | Connect to Google Play Billing service |
| `endConnection` | - | `null` | Disconnect from billing service |
| `queryProductDetails` | `List<String> productIds` | `BillingResult` | Query subscription product information |
| `getAvailableProducts` | - | `List<ProductInfo>` | Get cached product details |
| `startPurchase` | `String productId` | `BillingResult` | Initiate purchase flow with comprehensive state handling |
| `launchBillingFlow` | `String productId` | `BillingResult` | Legacy purchase method (deprecated) |
| `queryPurchases` | - | `BillingResult` | Query user's current purchases |
| `getCurrentPurchases` | - | `List<PurchaseInfo>` | Get cached purchase information |
| `acknowledgePurchase` | `String purchaseToken` | `BillingResult` | Acknowledge completed purchase |
| `warmProducts` | `List<String> productIds?` | `BillingResult` | Pre-cache product details for price backfill |
| `changeSubscription` | `String fromProductId, String toProductId, String? prorationMode` | `BillingResult` | Change subscription (placeholder - returns UNIMPLEMENTED) |

#### Subscription Change Parameters

The `changeSubscription` method accepts the following parameters:
- `fromProductId` (String, required): Current subscription product ID
- `toProductId` (String, required): Target subscription product ID  
- `prorationMode` (String, optional): Proration behavior, defaults to `"IMMEDIATE_WITH_TIME_PRORATION"`

**Note**: `changeSubscription` currently returns `DEVELOPER_ERROR` with message "UNIMPLEMENTED: Subscription changes require Play Console base plan configuration". This will be enabled once Google Play Console base plans are properly configured.

#### Timeout Behavior

All billing operations implement timeout guards to provide responsive user experience:

| Operation | Timeout | Behavior |
|-----------|---------|----------|
| `startConnection` | 6 seconds | Connection attempt timeout |
| `startPurchase` | 15 seconds | Purchase flow guard (non-blocking) |
| `queryPurchases` | 8 seconds | Restore operation timeout |
| `warmProducts` | N/A | Synchronous cache operation |

**Purchase Flow Timeout**: The 15-second purchase guard provides user feedback without failing the actual purchase. If Google Play takes longer than expected, users see a friendly message: "Still waiting on Google Play... You can close this message."

**Retry Behavior**: Failed operations use exponential backoff (200ms to 5000ms) for automatic retry.

### 2. Data Models (`models.dart`)
- **Purpose**: Type-safe data structures for billing operations
- **Key Classes**:
  - `BillingResult`: Operation results with response codes
  - `ProductInfo`: Subscription product details
  - `PurchaseInfo`: Purchase transaction data
  - `BillingProducts`: Product ID constants (deprecated - use `billing_constants.dart`)

### 3. Receipt Persistence (`receipt_store.dart`)
- **Purpose**: File-based storage for purchase receipts
- **Key Features**:
  - Atomic file operations (write-temp-rename)
  - Automatic receipt validation
  - Cross-session persistence
  - Pro status detection

### 4. Pro State Management (`pro_state.dart`)
- **Purpose**: Reactive Pro subscription status management
- **Key Features**:
  - Real-time Pro status updates
  - Automatic purchase restoration
  - Receipt-based state recovery
  - ChangeNotifier for UI reactivity

### 5. Billing Service (`billing_service.dart`)
- **Purpose**: Main interface between UI and billing system
- **Key Features**:
  - High-level billing operations
  - Product catalog management
  - Purchase flow orchestration
  - Error handling and user feedback

### 6. Fake Billing Adapter (`fake_billing_adapter.dart`)
- **Purpose**: Mock billing implementation for testing
- **Key Features**:
  - Configurable success/failure rates
  - Realistic delay simulation
  - Comprehensive error scenario testing
  - Purchase state simulation

### 7. Centralized Constants (`billing_constants.dart`)
- **Purpose**: Single source of truth for all billing constants
- **Key Features**:
  - Product IDs and mappings
  - Error codes and messages
  - Configuration values
  - Retry policies

## Product Configuration

### Subscription Products

| Product ID | Legacy ID | Display Name | Period | Price |
|------------|-----------|--------------|---------|-------|
| `mindtrainer_pro_monthly` | `pro_monthly` | Pro Monthly | 1 month | $9.99 |
| `mindtrainer_pro_yearly` | `pro_yearly` | Pro Yearly | 1 year | $99.99 |

### Legacy Compatibility

The system maintains backward compatibility with existing UI code through `BillingCatalogIntegration`:
- Automatic product ID mapping between legacy and new formats
- Legacy format conversion for existing components
- Seamless transition path for UI updates

## Usage Examples

### Basic Billing Service Usage

```dart
// Initialize billing service
final billingService = BillingService.instance;
await billingService.initialize();
await billingService.connect();

// Check Pro status
if (billingService.isProActive) {
  // User has active Pro subscription
}

// Purchase a subscription
final success = await billingService.purchaseProduct('mindtrainer_pro_monthly');
if (success) {
  // Purchase initiated successfully
}

// Restore purchases
await billingService.restorePurchases();
```

### Pro State Monitoring

```dart
// Listen to Pro state changes
final proState = ProState.instance;
proState.addListener(() {
  if (proState.isProActive) {
    // Pro subscription is active
    print('Pro active: ${proState.activeProductId}');
  }
});

// Get subscription info
final info = billingService.getSubscriptionInfo();
print('Status: ${info.isActive ? "Active" : "Inactive"}');
print('Plan: ${info.displayName}');
```

### Testing with Fake Adapter

```dart
// Configure fake billing for testing
final fakeAdapter = FakeBillingAdapter.instance;
fakeAdapter.setSuccessRate(1.0); // 100% success
fakeAdapter.setOperationDelay(Duration(milliseconds: 100));

// Add fake existing purchase
fakeAdapter.addFakePurchase('mindtrainer_pro_monthly');

// Test purchase flow
final result = await fakeAdapter.launchBillingFlow('mindtrainer_pro_yearly');
```

## Error Handling

The billing system provides comprehensive error handling with user-friendly messages:

### Error Categories

1. **User Errors**: Cancellation, item already owned
2. **System Errors**: Service unavailable, network issues
3. **Configuration Errors**: Developer setup issues
4. **Unknown Errors**: Unexpected failures

### Retry Logic

- Automatic retry for transient errors (network, service unavailable)
- Exponential backoff: 1s, 2s, 4s, 8s, max 30s
- Non-retryable errors: user cancellation, billing unavailable

### Error Messages

All error codes are mapped to user-friendly messages in `BillingErrorMessages`:

```dart
final errorMessage = BillingErrorMessages.forErrorCode('SERVICE_UNAVAILABLE');
// Returns: "Billing service is temporarily unavailable. Please try again later."
```

## Testing

### Test Structure

```
test/payments/
├── channel_test.dart              # Platform channel tests
├── models_test.dart              # Data model tests  
├── receipt_store_test.dart       # Persistence tests
├── pro_state_test.dart          # State management tests
├── billing_service_test.dart     # Integration tests
├── fake_billing_adapter_test.dart # Mock implementation tests
└── test_helpers/
    └── fake_path_provider_platform.dart
```

### Running Tests

```bash
# Run all billing tests
flutter test test/payments/

# Run specific test file
flutter test test/payments/billing_service_test.dart

# Run with coverage
flutter test --coverage test/payments/
```

### Test Categories

1. **Unit Tests**: Individual component functionality
2. **Integration Tests**: Service-level interactions  
3. **Mock Tests**: Fake adapter behavior
4. **Error Tests**: Comprehensive error scenarios
5. **State Tests**: Pro state transitions

## Security Considerations

### Receipt Validation
- All purchase receipts are validated before storage
- Invalid purchases are rejected and logged
- Receipt signatures are preserved for audit

### Local Storage
- Receipt files use atomic operations to prevent corruption
- Sensitive data is not logged in production
- File permissions restrict access to app-only

### Network Security
- All billing communication goes through Google Play Services
- No direct network calls to avoid man-in-the-middle attacks
- Purchase tokens are handled securely

## Performance Optimization

### Caching Strategy
- Product information is cached after successful query
- Receipt store maintains in-memory cache
- Pro state is computed once and cached until change

### Background Operations
- Purchase restoration happens asynchronously
- File I/O operations are performed off-main-thread
- Network operations have appropriate timeouts

### Memory Management
- Singleton instances prevent memory leaks
- Stream subscriptions are properly disposed
- Large data structures are cleared when not needed

## Troubleshooting

### Common Issues

1. **"Billing service unavailable"**
   - Check Google Play Services version
   - Verify app is signed with production certificate
   - Ensure products are configured in Play Console

2. **"Purchase not found during restoration"**
   - Check product IDs match Play Console configuration
   - Verify user account has active subscriptions
   - Clear app data and retry

3. **"Developer error"**
   - Verify app is properly configured in Play Console
   - Check product IDs match exactly
   - Ensure app is signed with correct certificate

### Debug Information

Enable debug mode to get detailed logging:

```dart
// Get comprehensive debug info
final debugInfo = proState.getDebugInfo();
print('Pro State Debug: $debugInfo');

// Check billing service status
print('Connected: ${billingService.isConnected}');
print('Products: ${billingService.availableProducts.length}');
print('Last Error: ${billingService.lastError}');
```

## Configuration

### Product Setup (Google Play Console)
1. Create in-app products with IDs matching `ProductIds` constants
2. Set pricing for all supported countries
3. Configure subscription periods and benefits
4. Publish products and app bundle

### Native Integration
The Dart implementation requires corresponding native Android code:
- `BillingHandler.kt`: Native billing implementation
- Method channel setup with name `mindtrainer/billing`
- Google Play Billing Library dependency

### Build Configuration
Ensure proper build configuration:
- `compileSdkVersion` 33 or higher
- Google Play Billing Library 5.0+
- Proper signing configuration for release builds

## Migration Guide

### From Legacy Billing
If migrating from an existing billing implementation:

1. **Preserve existing product IDs** in legacy format
2. **Use BillingCatalogIntegration** for seamless transition  
3. **Gradually update UI components** to use new service
4. **Test thoroughly** with existing user accounts
5. **Monitor receipt restoration** for existing subscribers

### Version Compatibility
- Supports Google Play Billing Library 5.0+
- Compatible with Android API 21+
- Requires Dart SDK 2.17+ for null safety

## Future Enhancements

### Planned Features
1. **Promotional codes** support
2. **Subscription upgrades/downgrades**
3. **Family sharing** integration  
4. **Analytics integration** for purchase events
5. **A/B testing** for pricing strategies

### Architecture Improvements
1. **Dependency injection** for better testability
2. **Event sourcing** for purchase history
3. **Background sync** for receipt validation
4. **Offline purchase queuing**

## Support

For issues or questions regarding the billing system:
1. Check this documentation first
2. Review test cases for usage examples
3. Check native Android implementation
4. Consult Google Play Billing documentation

## License

This billing system implementation is part of the MindTrainer application and follows the same licensing terms as the main project.