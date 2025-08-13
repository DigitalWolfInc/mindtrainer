class PriceCache {
  final Map<String, String> prices;
  final DateTime cachedAt;
  final Duration maxAge;

  const PriceCache._({
    required this.prices,
    required this.cachedAt,
    required this.maxAge,
  });

  factory PriceCache.empty() {
    return PriceCache._(
      prices: const {},
      cachedAt: DateTime.now(),
      maxAge: const Duration(hours: 24),
    );
  }

  factory PriceCache.create(Map<String, String> prices, {
    Duration? maxAge,
  }) {
    return PriceCache._(
      prices: Map.unmodifiable(prices),
      cachedAt: DateTime.now(),
      maxAge: maxAge ?? const Duration(hours: 24),
    );
  }

  bool get isStale {
    final age = DateTime.now().difference(cachedAt);
    return age > maxAge;
  }

  bool get isEmpty => prices.isEmpty;

  bool get isNotEmpty => prices.isNotEmpty;

  Duration get age => DateTime.now().difference(cachedAt);

  Duration? get timeUntilStale {
    final remainingTime = maxAge - age;
    return remainingTime.isNegative ? null : remainingTime;
  }

  String? getPriceForProduct(String productId) {
    return prices[productId];
  }

  bool hasPriceForProduct(String productId) {
    return prices.containsKey(productId);
  }

  List<String> get cachedProductIds => prices.keys.toList();

  PriceCache copyWith({
    Map<String, String>? prices,
    DateTime? cachedAt,
    Duration? maxAge,
  }) {
    return PriceCache._(
      prices: prices != null ? Map.unmodifiable(prices) : this.prices,
      cachedAt: cachedAt ?? this.cachedAt,
      maxAge: maxAge ?? this.maxAge,
    );
  }

  PriceCache updatePrices(Map<String, String> newPrices) {
    final updatedPrices = Map<String, String>.from(prices);
    updatedPrices.addAll(newPrices);
    
    return PriceCache._(
      prices: Map.unmodifiable(updatedPrices),
      cachedAt: DateTime.now(),
      maxAge: maxAge,
    );
  }

  PriceCache refresh() {
    return copyWith(cachedAt: DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'prices': prices,
      'cachedAt': cachedAt.toIso8601String(),
      'maxAgeMillis': maxAge.inMilliseconds,
    };
  }

  factory PriceCache.fromJson(Map<String, dynamic> json) {
    final pricesMap = json['prices'] as Map<String, dynamic>? ?? {};
    final prices = pricesMap.map((k, v) => MapEntry(k, v.toString()));
    
    return PriceCache._(
      prices: Map.unmodifiable(prices),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      maxAge: Duration(milliseconds: json['maxAgeMillis'] as int),
    );
  }

  @override
  String toString() {
    return 'PriceCache(${prices.length} prices, '
           'cached: ${cachedAt.toIso8601String()}, '
           'stale: $isStale, age: ${age.inMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceCache &&
            runtimeType == other.runtimeType &&
            _mapEquals(prices, other.prices) &&
            cachedAt == other.cachedAt &&
            maxAge == other.maxAge;
  }

  @override
  int get hashCode {
    return prices.hashCode ^
        cachedAt.hashCode ^
        maxAge.hashCode;
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}