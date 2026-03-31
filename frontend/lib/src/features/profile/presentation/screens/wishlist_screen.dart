import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/strings.dart';
import '../../../../core/api_client.dart';
import '../../../../core/session_storage.dart';
import '../../../masterclasses/domain/masterclass.dart';
import '../../../masterclasses/presentation/widgets/masterclass_card.dart';
import '../../data/profile_service.dart';

class WishlistScreen extends StatefulWidget {
  final String? userId;

  const WishlistScreen({super.key, this.userId});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _profileService = ProfileService(ApiClient());
  List<Masterclass> _allFavorites = [];
  bool _isLoading = true;
  String? _resolvedUserId;
  FavoritesProvider? _favoritesProvider;
  int _lastWishlistReloadNonce = -1;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<FavoritesProvider>();
      _favoritesProvider = p;
      _lastWishlistReloadNonce = p.wishlistReloadNonce;
      p.addListener(_onFavoritesProviderChanged);
    });
  }

  @override
  void dispose() {
    _favoritesProvider?.removeListener(_onFavoritesProviderChanged);
    super.dispose();
  }

  void _onFavoritesProviderChanged() {
    if (!mounted || _favoritesProvider == null) return;
    final n = _favoritesProvider!.wishlistReloadNonce;
    if (n != _lastWishlistReloadNonce) {
      _lastWishlistReloadNonce = n;
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    String? id = widget.userId;
    if (id == null || id.isEmpty) {
      id = await SessionStorage.getUserId();
    }
    if (!mounted) return;
    if (id == null || id.isEmpty) {
      context.go('/login');
      return;
    }
    _resolvedUserId = id;

    try {
      final favorites = await _profileService.getFavorites(id);
      if (!mounted) return;
      await context
          .read<FavoritesProvider>()
          .applyFavoritesFromServer(favorites);
      if (mounted) {
        setState(() {
          _allFavorites = favorites;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final visibleFavorites = _allFavorites
            .where((m) => favoritesProvider.isFavorite(m.id))
            .toList();

        final uid = _resolvedUserId;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: Text(
              AppStrings.favorites,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          body: _isLoading || uid == null
              ? const Center(child: CircularProgressIndicator())
              : visibleFavorites.isEmpty
                  ? Center(child: Text(AppStrings.wishlistEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: visibleFavorites.length,
                      itemBuilder: (context, index) {
                        final masterclass = visibleFavorites[index];
                        return MasterclassCard(
                          key: ValueKey<int>(masterclass.id),
                          masterclass: masterclass,
                          isFavorite: true,
                          onFavoritePressed: () async {
                            await favoritesProvider.toggleFavorite(
                                uid, masterclass.id);
                          },
                        );
                      },
                    ),
        );
      },
    );
  }
}
