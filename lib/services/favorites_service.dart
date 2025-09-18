import '../favorites/favorite_tools_store.dart';

/// Service layer for favorites functionality
/// 
/// Provides a clean API over the FavoriteToolsStore for business logic
class FavoritesService {
  static FavoritesService? _instance;
  final FavoriteToolsStore _store;

  FavoritesService._(this._store);

  /// Singleton instance
  static FavoritesService get instance {
    _instance ??= FavoritesService._(FavoriteToolsStore.instance);
    return _instance!;
  }

  /// For testing - reset the singleton
  static void resetInstance() {
    _instance = null;
  }

  /// Add a tool to favorites
  Future<void> addFavorite(String id) async {
    await _store.addFavorite(id);
  }

  /// Remove a tool from favorites
  Future<void> removeFavorite(String id) async {
    await _store.removeFavorite(id);
  }

  /// Check if a tool is favorited
  bool isFavorite(String id) {
    return _store.isFavorite(id);
  }

  /// Get all favorite tool IDs in order (most recent first)
  List<String> getFavorites() {
    return _store.getFavorites();
  }

  /// Initialize the service
  Future<void> init() async {
    await _store.init();
  }
}