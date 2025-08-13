import '../models/coach_models.dart';
import '../../../support/logger.dart';
import 'local_coach_provider.dart';

/// Remote coach provider (stubbed for future implementation)
/// Falls back to local provider when not configured or offline
class RemoteCoachProvider implements CoachProvider {
  final LocalCoachProvider _fallback = LocalCoachProvider();
  final String? _apiKey;
  final String? _endpoint;
  
  const RemoteCoachProvider({
    String? apiKey,
    String? endpoint,
  }) : _apiKey = apiKey, _endpoint = endpoint;
  
  @override
  Future<CoachReply> reply(String userText, {String? triageTag}) async {
    // Check if remote service is configured
    if (!_isConfigured) {
      Log.debug('RemoteCoachProvider not configured, using local fallback');
      return _fallback.reply(userText, triageTag: triageTag);
    }
    
    try {
      // TODO: Implement actual remote API call
      // For now, simulate network delay then fallback
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Simulate failure/offline scenario - always fallback for now
      throw Exception('Remote service not implemented');
      
    } catch (e) {
      Log.debug('RemoteCoachProvider failed, using local fallback: $e');
      return _fallback.reply(userText, triageTag: triageTag);
    }
  }
  
  /// Check if remote service is properly configured
  bool get _isConfigured => _apiKey != null && _endpoint != null;
  
  /// Factory for configured remote provider
  factory RemoteCoachProvider.configured({
    required String apiKey,
    required String endpoint,
  }) {
    return RemoteCoachProvider(apiKey: apiKey, endpoint: endpoint);
  }
  
  /// Factory for unconfigured provider (always falls back)
  factory RemoteCoachProvider.stub() {
    return const RemoteCoachProvider();
  }
}