/// Email Opt-in Management for MindTrainer
/// 
/// Privacy-safe email consent storage and management. No actual email sending
/// occurs here - this only stores user consent for later server-side enrollment.

/// Abstract key-value store for consent persistence
/// 
/// App will implement this via SharedPreferences or similar platform storage.
abstract class KVStore {
  /// Store a boolean value
  Future<void> setBool(String key, bool value);
  
  /// Retrieve a boolean value (null if not set)
  bool? getBool(String key);
  
  /// Store a string value
  Future<void> setString(String key, String value);
  
  /// Retrieve a string value (null if not set)
  String? getString(String key);
  
  /// Remove a key
  Future<void> remove(String key);
}

/// Manager for email opt-in consent
/// 
/// Stores consent locally only. Actual email enrollment happens server-side
/// using this consent flag as authorization.
class EmailOptInManager {
  static const String _optInKey = "email_opt_in_v1";
  static const String _emailKey = "email_opt_in_address_v1";
  static const String _timestampKey = "email_opt_in_timestamp_v1";
  
  final KVStore _store;
  
  const EmailOptInManager(this._store);
  
  /// Whether user has opted in to email updates
  bool get isOptedIn => _store.getBool(_optInKey) ?? false;
  
  /// Stored email address (if provided)
  String? get emailAddress => _store.getString(_emailKey);
  
  /// Timestamp when consent was given (ISO 8601 string)
  String? get consentTimestamp => _store.getString(_timestampKey);
  
  /// Set email opt-in preference
  /// 
  /// [optedIn] - Whether user consents to email updates
  /// [emailAddress] - Optional email address (can be provided later)
  Future<void> setOptIn(bool optedIn, {String? emailAddress}) async {
    await _store.setBool(_optInKey, optedIn);
    
    if (optedIn) {
      // Record timestamp when consent was given
      final timestamp = DateTime.now().toIso8601String();
      await _store.setString(_timestampKey, timestamp);
      
      // Store email if provided
      if (emailAddress != null && emailAddress.trim().isNotEmpty) {
        await _store.setString(_emailKey, emailAddress.trim());
      }
    } else {
      // Clear all email-related data when opting out (including the opt-in flag)
      await _store.remove(_optInKey);
      await _store.remove(_emailKey);
      await _store.remove(_timestampKey);
    }
  }
  
  /// Update stored email address (only if already opted in)
  Future<void> updateEmailAddress(String emailAddress) async {
    if (!isOptedIn) {
      throw StateError('Cannot update email address without consent');
    }
    
    if (emailAddress.trim().isEmpty) {
      await _store.remove(_emailKey);
    } else {
      await _store.setString(_emailKey, emailAddress.trim());
    }
  }
  
  /// Revoke email consent and clear all stored data
  Future<void> revokeConsent() async {
    await _store.remove(_optInKey);
    await _store.remove(_emailKey);
    await _store.remove(_timestampKey);
  }
  
  /// Get consent summary for export/audit purposes
  Map<String, dynamic> getConsentSummary() {
    return {
      'opted_in': isOptedIn,
      'email_address': emailAddress,
      'consent_timestamp': consentTimestamp,
      'version': 1,
    };
  }
}

