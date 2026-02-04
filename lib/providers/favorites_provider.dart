import 'package:flutter/material.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<int> _favoriteIds = <int>{};

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  List<int> get favorites => _favoriteIds.toList(growable: false);

  void toggleFavorite(int productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  void clear() {
    _favoriteIds.clear();
    notifyListeners();
  }
}
