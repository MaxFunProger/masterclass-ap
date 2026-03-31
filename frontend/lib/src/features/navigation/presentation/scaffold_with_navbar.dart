import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/session_storage.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  static const double _navIconSize = 28;

  Future<void> _onItemTapped(int index, BuildContext context) async {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        final favUserId = await SessionStorage.getUserId();
        if (context.mounted) {
          context.read<FavoritesProvider>().bumpWishlistReloadNonce();
          if (favUserId != null) {
            context.go('/wishlist?user_id=$favUserId');
          } else {
            context.go('/wishlist');
          }
        }
        break;
      case 3:
        final userId = await SessionStorage.getUserId();
        if (context.mounted) {
          if (userId != null) {
            context.go('/profile?user_id=$userId');
          } else {
            context.go('/profile');
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: _navIconSize),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headset, size: _navIconSize),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, size: _navIconSize),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: _navIconSize),
            label: '',
          ),
        ],
        selectedItemColor: const Color(0xFFE67E22),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
