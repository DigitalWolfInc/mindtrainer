/// Support Bundle Generator for MindTrainer
/// 
/// Creates diagnostic bundles for user support with privacy-safe information.
/// All operations require explicit user consent.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'package:flutter/foundation.dart';
import 'logger.dart';

/// Support bundle metadata
class BundleMetadata {
  final String bundleId;
  final DateTime createdAt;
  final String appVersion;
  final String bundleVersion;
  
  const BundleMetadata({
    required this.bundleId,
    required this.createdAt,
    required this.appVersion,
    this.bundleVersion = '1.0',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'bundle_id': bundleId,
      'created_at': createdAt.toIso8601String(),
      'app_version': appVersion,
      'bundle_version': bundleVersion,
    };
  }
}

/// Device and environment information (privacy-safe)
class EnvironmentInfo {
  final String platform;
  final String locale;
  final bool isDebugMode;
  final Map<String, bool> features;
  
  const EnvironmentInfo({
    required this.platform,
    required this.locale,
    required this.isDebugMode,
    required this.features,
  });
  
  static EnvironmentInfo gather(BuildContext context) {
    return EnvironmentInfo(
      platform: defaultTargetPlatform.name,
      locale: Localizations.localeOf(context).toString(),
      isDebugMode: kDebugMode,
      features: {
        'file_system_available': !kIsWeb,
        'accessibility_enabled': MediaQuery.accessibleNavigationOf(context),
        'high_contrast': false, // Will be updated when settings are connected
        'reduced_motion': MediaQuery.disableAnimationsOf(context),
      },
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'locale': locale,
      'debug_mode': isDebugMode,
      'features': features,
    };
  }
}

/// App configuration snapshot
class ConfigSnapshot {
  final bool proActive;
  final List<String> availableSkus;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> settings;
  
  const ConfigSnapshot({
    required this.proActive,
    required this.availableSkus,
    required this.featureFlags,
    required this.settings,
  });
  
  static ConfigSnapshot gather() {
    return ConfigSnapshot(
      proActive: false, // TODO: Connect to actual Pro status
      availableSkus: ['pro_monthly', 'pro_yearly'], // TODO: Connect to actual catalog
      featureFlags: {
        'diagnostics_enabled': true,
        'file_logging_enabled': MindTrainerLogger.instance.canUseFileLogging,
        'high_contrast_available': true,
        'i18n_enabled': true,
      },
      settings: {
        'theme_mode': 'system', // TODO: Connect to actual settings
        'notifications_enabled': true,
        'weekly_goal_minutes': 150,
      },
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'pro_active': proActive,
      'available_skus': availableSkus,
      'feature_flags': featureFlags,
      'settings': settings,
    };
  }
}

/// Fields intentionally redacted from the support bundle
class RedactionInfo {
  final List<String> redactedFields;
  final String reason;
  
  const RedactionInfo({
    required this.redactedFields,
    required this.reason,
  });
  
  static const privacy = RedactionInfo(
    redactedFields: [
      'user_session_notes',
      'user_personal_data',
      'device_identifiers',
      'precise_timestamps',
      'ip_addresses',
      'location_data',
    ],
    reason: 'Privacy protection - personal data is never included in support bundles',
  );
  
  Map<String, dynamic> toJson() {
    return {
      'redacted_fields': redactedFields,
      'reason': reason,
    };
  }
}

/// Support bundle creation result
class BundleResult {
  final bool success;
  final String? bundlePath;
  final String? error;
  final int? fileSizeBytes;
  final BundleMetadata? metadata;
  
  const BundleResult({
    required this.success,
    this.bundlePath,
    this.error,
    this.fileSizeBytes,
    this.metadata,
  });
  
  BundleResult.success({
    required String bundlePath,
    required int fileSizeBytes,
    required BundleMetadata metadata,
  }) : this(
    success: true,
    bundlePath: bundlePath,
    fileSizeBytes: fileSizeBytes,
    metadata: metadata,
  );
  
  BundleResult.error(String error) : this(
    success: false,
    error: error,
  );
}

/// Main support bundle generator
class SupportBundleGenerator {
  static const String bundleFileName = 'mindtrainer_support_bundle.zip';
  
  /// Generate a complete support bundle
  static Future<BundleResult> createBundle({
    required BuildContext context,
    required bool userConsent,
    bool includeFullLogs = true,
  }) async {
    if (!userConsent) {
      return BundleResult.error('User consent required for support bundle creation');
    }
    
    if (kIsWeb) {
      return BundleResult.error('Support bundles not available on web platform');
    }
    
    try {
      // Generate bundle metadata
      final metadata = BundleMetadata(
        bundleId: 'bundle_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        appVersion: '1.0.0', // TODO: Get from package info
      );
      
      // Gather information
      final envInfo = EnvironmentInfo.gather(context);
      final configInfo = ConfigSnapshot.gather();
      final logger = MindTrainerLogger.instance;
      
      // Prepare bundle contents
      final bundleContents = <String, String>{
        'metadata.json': jsonEncode(metadata.toJson()),
        'environment.json': jsonEncode(envInfo.toJson()),
        'config_snapshot.json': jsonEncode(configInfo.toJson()),
        'redactions.json': jsonEncode(RedactionInfo.privacy.toJson()),
      };
      
      // Add logs if requested
      if (includeFullLogs) {
        bundleContents['logs.json'] = logger.exportLogsAsJson();
        bundleContents['logs.txt'] = logger.exportLogsAsText();
        bundleContents['logger_stats.json'] = jsonEncode(logger.getBufferStats());
      } else {
        // Include only recent error logs
        final errorLogs = logger.getLogsByLevel(LogLevel.error)
            .take(50) // Last 50 errors
            .map((e) => e.toJson())
            .toList();
        bundleContents['error_logs.json'] = jsonEncode(errorLogs);
      }
      
      // Write bundle to file
      final bundlePath = await _writeBundleToFile(bundleContents, metadata.bundleId);
      final file = File(bundlePath);
      final fileSize = await file.length();
      
      return BundleResult.success(
        bundlePath: bundlePath,
        fileSizeBytes: fileSize,
        metadata: metadata,
      );
      
    } catch (e, stackTrace) {
      MindTrainerLogger.instance.error(
        'Failed to create support bundle: $e',
        tag: 'SupportBundle',
        extra: {'stack_trace': stackTrace.toString()},
      );
      return BundleResult.error('Failed to create support bundle: $e');
    }
  }
  
  /// Create a minimal bundle for quick issue reporting
  static Future<BundleResult> createMinimalBundle({
    required BuildContext context,
    required bool userConsent,
  }) async {
    return createBundle(
      context: context,
      userConsent: userConsent,
      includeFullLogs: false,
    );
  }
  
  /// Write bundle contents to a pseudo-ZIP file (simplified implementation)
  static Future<String> _writeBundleToFile(
    Map<String, String> contents,
    String bundleId,
  ) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final bundlePath = '${documentsDir.path}/${bundleId}_support_bundle.txt';
    
    final file = File(bundlePath);
    final buffer = StringBuffer();
    
    buffer.writeln('MindTrainer Support Bundle');
    buffer.writeln('Bundle ID: $bundleId');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 60);
    buffer.writeln();
    
    // Write each file section
    for (final entry in contents.entries) {
      buffer.writeln('FILE: ${entry.key}');
      buffer.writeln('-' * 40);
      buffer.writeln(entry.value);
      buffer.writeln();
      buffer.writeln('=' * 60);
      buffer.writeln();
    }
    
    await file.writeAsString(buffer.toString());
    return bundlePath;
  }
  
  /// Create bundle and prepare for email sharing
  static Future<Map<String, dynamic>> createAndPrepareForEmail({
    required BuildContext context,
    required bool userConsent,
    String? userDescription,
  }) async {
    final result = await createBundle(
      context: context,
      userConsent: userConsent,
    );
    
    if (!result.success) {
      return {
        'success': false,
        'error': result.error,
      };
    }
    
    // Prepare email content
    final emailSubject = 'MindTrainer Support Request - ${result.metadata!.bundleId}';
    final emailBody = '''
Hello MindTrainer Support Team,

I'm experiencing an issue with the MindTrainer app and would like to request assistance.

${userDescription ?? 'No additional description provided.'}

I've attached a support bundle with diagnostic information to help you investigate the issue.

Bundle Information:
- Bundle ID: ${result.metadata!.bundleId}
- Created: ${result.metadata!.createdAt.toIso8601String()}
- File Size: ${_formatBytes(result.fileSizeBytes!)}
- File Path: ${result.bundlePath}

Please note that this bundle contains only diagnostic information and no personal data.

Thank you for your support!
''';
    
    return {
      'success': true,
      'email_subject': emailSubject,
      'email_body': emailBody,
      'bundle_path': result.bundlePath,
      'bundle_size': result.fileSizeBytes,
      'bundle_id': result.metadata!.bundleId,
    };
  }
  
  /// Clean up old support bundles
  static Future<void> cleanupOldBundles({int maxAge = 7}) async {
    if (kIsWeb) return;
    
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final directory = Directory(documentsDir.path);
      
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAge));
      
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.contains('support_bundle')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            MindTrainerLogger.instance.info(
              'Cleaned up old support bundle: ${entity.path}',
              tag: 'SupportBundle',
            );
          }
        }
      }
    } catch (e) {
      MindTrainerLogger.instance.warn(
        'Failed to clean up old support bundles: $e',
        tag: 'SupportBundle',
      );
    }
  }
  
  /// Format file size in human-readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}