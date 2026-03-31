import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/favorites_provider.dart';
import 'features/chat/chat_state.dart';
import 'features/auth/presentation/screens/tutorial_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/auth/presentation/screens/start_screen.dart';

import 'features/masterclasses/presentation/screens/feed_screen.dart';
import 'features/masterclasses/presentation/screens/masterclass_details_screen.dart';
import 'features/masterclasses/domain/masterclass.dart';

import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/profile_data_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/profile/presentation/screens/about_app_screen.dart';
import 'features/profile/presentation/screens/wishlist_screen.dart';

import 'features/navigation/presentation/scaffold_with_navbar.dart';
import 'features/chat/presentation/screens/chat_screen.dart';

class MasterclassesApp extends StatelessWidget {
  const MasterclassesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final chat = ChatState();
        Future.microtask(() => chat.loadPersistedUi());
        return chat;
      },
      child: ChangeNotifierProvider(
        create: (_) => FavoritesProvider(),
        child: const _AppWithChatLifecycle(),
      ),
    );
  }
}

/// Сброс контекста чата при завершении процесса приложения.
class _AppWithChatLifecycle extends StatefulWidget {
  const _AppWithChatLifecycle();

  @override
  State<_AppWithChatLifecycle> createState() => _AppWithChatLifecycleState();
}

class _AppWithChatLifecycleState extends State<_AppWithChatLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      context.read<ChatState>().clearLlmSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'canDo!',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: const Color(0xFFE67E22)), // Orange
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGateScreen(),
    ),
    GoRoute(
      path: '/start',
      builder: (context, state) => const StartScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (context, state) {
                final q = state.uri.queryParameters['user_id'];
                return WishlistScreen(
                  userId: (q == null || q.isEmpty) ? null : q,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                final userId = state.uri.queryParameters['user_id'];
                return ProfileScreen(userId: userId);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/masterclass',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final masterclass = extra['masterclass'] as Masterclass;
        return MasterclassDetailsScreen(masterclass: masterclass);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutAppScreen(),
    ),
    GoRoute(
      path: '/profile/data',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        return ProfileDataScreen(phoneFromProfile: phone);
      },
    ),
  ],
);
