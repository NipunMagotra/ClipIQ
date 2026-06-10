import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<User?> {
  StreamSubscription<AuthState>? _authSub;

  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);

    // Seed the initial state from current session.
    final currentUser = repo.currentUser;

    // Listen to auth state changes and update the notifier.
    _authSub?.cancel();
    _authSub = repo.authStateChanges.listen((authState) {
      state = AsyncData(authState.session?.user);
    });

    // Clean up when the provider is disposed.
    ref.onDispose(() => _authSub?.cancel());

    return currentUser;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<String?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.signInWithEmailPassword(
          email: email, password: password);
      state = AsyncData(res.user);
      return null; // No error.
    } catch (e) {
      state = AsyncData(ref.read(authRepositoryProvider).currentUser);
      return e.toString();
    }
  }

  Future<String?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.signUpWithEmailPassword(
          email: email, password: password);
      state = AsyncData(res.user);
      return null;
    } catch (e) {
      state = AsyncData(ref.read(authRepositoryProvider).currentUser);
      return e.toString();
    }
  }

  Future<String?> sendMagicLink(String email) async {
    try {
      await ref.read(authRepositoryProvider).sendMagicLink(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}
