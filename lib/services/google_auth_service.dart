import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:offroad_nav/services/user_repository.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  final _auth = FirebaseAuth.instance;
  final _gsi  = gsi.GoogleSignIn.instance;

  bool _gsiInited = false;

Future<void> _ensureGsiInit() async {
  if (_gsiInited) return;
  if (Platform.isIOS || Platform.isMacOS) {
    // clientId из GoogleService-Info.plist (CLIENT_ID)
    await _gsi.initialize(clientId: '273719108763-1s43no6cq286trqn0bmhqtl5mpdtv92r.apps.googleusercontent.com');
  } else if (Platform.isAndroid) {
    // Web client ID из android/app/google-services.json (oauth_client client_type:3)
    await _gsi.initialize(serverClientId: '273719108763-ke0ppdq2lso9jsgqnm7c5af7r4t12r6l.apps.googleusercontent.com');
  }
  _gsiInited = true;
}

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final cred = await _auth.signInWithPopup(provider);
      await _upsert(cred.user);
      return cred;
    }

    await _ensureGsiInit();                       

      try {
        // в v7 можно просто попытаться отключить/выйти — если не залогинен, SDK сам бросит/проглотит
        await _gsi.disconnect(); // может бросить — ок
      } catch (_) {}
      try {
        await _gsi.signOut();
      } catch (_) {}

    try {
      final account = await _gsi.authenticate();    // v7: вместо signIn()
    final auth    = await account.authentication; // содержит ТОЛЬКО idToken

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,                      // accessToken в v7 не нужен
    );

    final cred = await _auth.signInWithCredential(credential);
    await _upsert(cred.user);
    return cred;
    } on gsi.GoogleSignInException catch (e) {
            if (e.code == gsi.GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(code: 'aborted-by-user', message: 'Sign-in cancelled');
      }
      throw FirebaseAuthException(code: 'google-sign-in-failed', message: e.toString());
    }

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