import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/clipboard/presentation/pages/home_page.dart';
import 'features/clipboard/presentation/pages/settings_page.dart';

// ── Router provider ────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = user != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (ctx, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (ctx, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (ctx, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    // Refresh the router whenever auth state changes.
    refreshListenable: _AuthChangeNotifier(),
  );
});

// ── Auth change notifier (for GoRouter refresh) ────────────────────────────────

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}
