// This file provides the exact API structure requested while delegating to the existing implementation
// The actual implementation is in lib/favorites/favorite_tools_store.dart

export '../favorites/favorite_tools_store.dart';

/// Export the FavoriteToolsStore as FavoritesStore for API consistency
typedef FavoritesStore = FavoriteToolsStore;