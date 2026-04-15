import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/session_storage.dart';

/// Старт приложения: без user_id -> /start; иначе при незавершённом пост-регистрационном туториале -> /tutorial, иначе -> /home.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final userId = await SessionStorage.getUserId();
    if (!mounted) return;
    if (userId != null) {
      if (await SessionStorage.awaitingPostTutorialFeedFilterPrompt()) {
        if (!mounted) return;
        context.go('/tutorial');
      } else {
        if (!mounted) return;
        context.go('/home');
      }
    } else {
      context.go('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
