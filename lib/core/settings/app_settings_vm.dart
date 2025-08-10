/// App Settings View Model for MindTrainer
/// 
/// Integrates Pro subscriptions, charity messaging, and email opt-in
/// into a unified settings interface for the UI layer.

import '../payments/pro_manager.dart';
import '../payments/charity_messaging.dart';
import '../consent/email_optin.dart';

/// View model for app settings screen
/// 
/// Provides unified access to subscription status, charity information,
/// and consent management for the UI layer.
class AppSettingsVM {
  final EmailOptInManager _email;
  final CharityPolicy _charity;
  final ProManager _pro;
  
  const AppSettingsVM({
    required EmailOptInManager email,
    required CharityPolicy charity,
    required ProManager pro,
  }) : _email = email,
       _charity = charity,
       _pro = pro;
  
  // Charity messaging
  
  /// Charity messaging copy for display
  String get charityCopy => charityBlurb(_charity);
  
  /// External donation link (null if not configured)
  Uri? get donateLink => _charity.externalDonate;
  
  /// Charity revenue share as percentage (e.g., "33%" for 1/3)
  String get charitySharePercent => '${(_charity.share * 100).round()}%';
  
  // Pro subscription status
  
  /// Whether Pro subscription is currently active
  bool get proActive => _pro.isProActive;
  
  /// Current Pro status for display
  String get proStatusText {
    if (!_pro.current.active) {
      return 'Free';
    } else if (_pro.current.isPro) {
      return 'Pro';
    } else {
      return 'Unknown';
    }
  }
  
  /// Pro subscription expiration (null if no expiration or not Pro)
  DateTime? get proExpiresAt => _pro.current.expiresAt;
  
  /// Whether Pro subscription auto-renews
  bool get proAutoRenewing => _pro.current.autoRenewing;
  
  /// Available Pro features list
  List<String> get proFeatures {
    final gate = DefaultProGate(_pro);
    return gate.proFeatures;
  }
  
  // Email consent
  
  /// Whether user has opted in to email updates
  bool get emailOptedIn => _email.isOptedIn;
  
  /// Stored email address (null if not provided)
  String? get emailAddress => _email.emailAddress;
  
  /// When email consent was given (for privacy audit)
  String? get emailConsentTimestamp => _email.consentTimestamp;
  
  /// Whether email address is missing (opted in but no address stored)
  bool get emailAddressMissing => emailOptedIn && emailAddress == null;
  
  // Actions
  
  /// Set email opt-in preference
  Future<void> setEmailOptIn(bool optedIn, {String? emailAddress}) async {
    await _email.setOptIn(optedIn, emailAddress: emailAddress);
  }
  
  /// Update email address (only if already opted in)
  Future<void> updateEmailAddress(String emailAddress) async {
    await _email.updateEmailAddress(emailAddress);
  }
  
  /// Revoke email consent completely
  Future<void> revokeEmailConsent() async {
    await _email.revokeConsent();
  }
  
  /// Refresh Pro subscription status
  Future<void> refreshProStatus() async {
    await _pro.refreshStatus();
  }
  
  /// Get Pro subscription manager (for purchase flows)
  ProManager get proManager => _pro;
  
  /// Get consent summary for export
  Map<String, dynamic> getPrivacyExport() {
    return {
      'email_consent': _email.getConsentSummary(),
      'pro_status': {
        'tier': _pro.current.tier.name,
        'active': _pro.current.active,
        'expires_at': _pro.current.expiresAt?.toIso8601String(),
      },
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Factory for creating AppSettingsVM with default configuration
class AppSettingsVMFactory {
  /// Create settings VM with default charity policy
  static AppSettingsVM create({
    required EmailOptInManager email,
    required ProManager pro,
    Uri? donateLink,
  }) {
    final charity = CharityPolicy.defaultPolicy(externalDonate: donateLink);
    
    return AppSettingsVM(
      email: email,
      charity: charity,
      pro: pro,
    );
  }
  
  /// Create settings VM with custom charity policy
  static AppSettingsVM createWithPolicy({
    required EmailOptInManager email,
    required ProManager pro,
    required CharityPolicy charity,
  }) {
    return AppSettingsVM(
      email: email,
      charity: charity,
      pro: pro,
    );
  }
}