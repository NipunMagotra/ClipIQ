import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for Supabase Auth operations.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  // ── Getters ───────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  /// Sends a Magic Link to [email]. The user taps the link and is logged in.
  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      emailRedirectTo: kIsWeb ? null : 'clipq://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
