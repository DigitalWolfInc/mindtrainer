import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Store for managing user's favorite tools
/// Uses atomic file operations for persistence, similar to AchievementsStore
class FavoriteToolsStore extends ChangeNotifier {
  static FavoriteToolsStore? _instance;
  
  Set<String> _favoriteIds = <String>{};
  List<String> _favoriteOrder = []; // Most recently favorited first
  String? _filePath;
  bool _initialized = false;

  /// Singleton instance
  static FavoriteToolsStore get instance {
    _instance ??= FavoriteToolsStore._();
    return _instance!;
  }

  FavoriteToolsStore._();

  /// For testing - reset the singleton
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Initialize the store with optional file path
  Future<void> init({String? filePath}) async {
    if (_initialized) return;
    
    _filePath = filePath ?? await _getDefaultFilePath();
    await _loadFromFile();
    _initialized = true;
  }

  /// Get default file path in app data directory
  Future<String> _getDefaultFilePath() async {
    // Use same approach as other stores - local app data
    const fileName = 'favorite_tools.json';
    
    // For now, use current directory (same as achievements)
    // In production, this would use proper app data directory
    return fileName;
  }

  /// Load favorites from file
  Future<void> _loadFromFile() async {
    if (_filePath == null) return;
    
    try {
      final file = File(_filePath!);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final favoritesList = (data['favorites'] as List?)?.cast<String>() ?? [];
        _favoriteOrder = List<String>.from(favoritesList);
        _favoriteIds = Set<String>.from(favoritesList);
      }
    } catch (e) {
      // Graceful fallback on any error
      _favoriteIds = <String>{};
      _favoriteOrder = [];
    }
  }

  /// Save favorites to file atomically
  Future<void> _saveToFile() async {
    if (_filePath == null) return;
    
    try {
      final data = {
        'favorites': _favoriteOrder,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final jsonString = jsonEncode(data);
      
      // Atomic write using temp file
      final tempFile = File('${_filePath!}.tmp');
      await tempFile.writeAsString(jsonString);
      await tempFile.rename(_filePath!);
    } catch (e) {
      // Silent failure - don't crash app if file operations fail
    }
  }

  /// Add a tool to favorites
  Future<void> addFavorite(String toolId) async {
    if (_favoriteIds.contains(toolId)) return;
    
    _favoriteIds.add(toolId);
    // Add to front of order list (most recent first)
    _favoriteOrder.insert(0, toolId);
    
    await _saveToFile();
    notifyListeners();
  }

  /// Remove a tool from favorites
  Future<void> removeFavorite(String toolId) async {
    if (!_favoriteIds.contains(toolId)) return;
    
    _favoriteIds.remove(toolId);
    _favoriteOrder.remove(toolId);
    
    await _saveToFile();
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String toolId) async {
    if (isFavorite(toolId)) {
      await removeFavorite(toolId);
    } else {
      await addFavorite(toolId);
    }
  }

  /// Check if a tool is favorited
  bool isFavorite(String toolId) {
    return _favoriteIds.contains(toolId);
  }

  /// Get all favorite tool IDs in order (most recent first)
  List<String> getFavorites() {
    return List<String>.from(_favoriteOrder);
  }

  /// Get up to N favorites for display
  List<String> getTopFavorites(int count) {
    return _favoriteOrder.take(count).toList();
  }

  /// Get number of favorites
  int get favoriteCount => _favoriteIds.length;

  /// Check if there are any favorites
  bool get hasFavorites => _favoriteIds.isNotEmpty;
}