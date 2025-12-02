import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../../../services/user_repository.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _gsi  = gsi.GoogleSignIn.instance;

  bool _gsiInited = false;
  Future<void> _ensureGsiInit() async {
    if (_gsiInited) return;
    await _gsi.initialize(
      serverClientId: "273719108763-ke0ppdq2lso9jsgqnm7c5af7r4t12r6l.apps.googleusercontent.com", // Android
      // Для iOS/macOS, если потребуется:
      // clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    );
    _gsiInited = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final cred = await _auth.signInWithPopup(provider);
      await _upsert(cred.user);
      return cred;
    }

    await _ensureGsiInit();                       // 👈 без scopes

    final account = await _gsi.authenticate();    // v7: вместо signIn()
    final auth    = await account.authentication; // содержит ТОЛЬКО idToken

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,                      // accessToken в v7 не нужен
    );

    final cred = await _auth.signInWithCredential(credential);
    await _upsert(cred.user);
    return cred;
  }

  Future<void> signOut() async {
    try { await _gsi.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<void> _upsert(User? u) async {
    if (u == null) return;
    await UserRepository.upsertOnLogin(u, extra: {
      'name' : u.displayName ?? '',
      'img'  : u.photoURL ?? '',
      'email': u.email ?? '',
    });
  }
}