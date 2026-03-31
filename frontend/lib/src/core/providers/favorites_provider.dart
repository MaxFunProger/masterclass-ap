import 'package:flutter/material.dart';

import '../../features/masterclasses/domain/masterclass.dart';
import '../../features/profile/data/profile_service.dart';
import '../api_client.dart';

/// Очередь GET/POST по избранному, иначе гонки и сброс локального состояния.
class FavoritesProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService(ApiClient());
  Set<int> _favoriteIds = {};
  bool _isLoading = false;
  int _wishlistReloadNonce = 0;
  Future<void> _mutationTail = Future.value();

  Set<int> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  int get wishlistReloadNonce => _wishlistReloadNonce;

  void bumpWishlistReloadNonce() {
    _wishlistReloadNonce++;
    notifyListeners();
  }

  bool isFavorite(int masterclassId) => _favoriteIds.contains(masterclassId);

  void clear() {
    _favoriteIds.clear();
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final run = _mutationTail.then((_) => job());
    _mutationTail = run.then((_) {}, onError: (_, __) {});
    return run;
  }

  Future<void> loadFavorites(String userId) {
    return _enqueue(() async {
      _isLoading = true;
      notifyListeners();
      try {
        final favorites = await _profileService.getFavorites(userId);
        _favoriteIds = favorites.map((e) => e.id).toSet();
      } catch (_) {
        // сеть / 5xx - не затираем кэш
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> applyFavoritesFromServer(List<Masterclass> favorites) {
    return _enqueue(() async {
      _favoriteIds = favorites.map((e) => e.id).toSet();
      notifyListeners();
    });
  }

  Future<void> toggleFavorite(String userId, int masterclassId) {
    return _enqueue(() async {
      final wasFavorite = _favoriteIds.contains(masterclassId);
      if (wasFavorite) {
        _favoriteIds.remove(masterclassId);
      } else {
        _favoriteIds.add(masterclassId);
      }
      notifyListeners();

      try {
        if (wasFavorite) {
          await _profileService.removeFavorite(userId, masterclassId);
        } else {
          await _profileService.addFavorite(userId, masterclassId);
        }
      } catch (_) {
        if (wasFavorite) {
          _favoriteIds.add(masterclassId);
        } else {
          _favoriteIds.remove(masterclassId);
        }
        notifyListeners();
      }
    });
  }
}
