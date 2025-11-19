import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'authentication_enums.dart';
import 'cache.dart';
import 'user.dart';

abstract class AuthenticationRepository {}

// Without Firebase Custom Backend Authentication Purpose Not Used In This Project
// DO NOT USE THIS CLASS IN THIS PROJECT
class CredentialAuthenticationRepository extends AuthenticationRepository {
  final _controller = StreamController<AuthenticationStatus>();

  Stream<AuthenticationStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield AuthenticationStatus.unauthenticated;
    yield* _controller.stream;
  }

  Future<void> logIn({required String username, required String password}) async {
    await Future.delayed(
      const Duration(milliseconds: 300),
      () => _controller.add(AuthenticationStatus.authenticated),
    );
  }

  Future<void> signUp({
    required String username,
    required String password,
    required String email,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 300),
      () => _controller.add(AuthenticationStatus.authenticated),
    );
  }

  void logOut() {
    _controller.add(AuthenticationStatus.unauthenticated);
  }

  void dispose() => _controller.close();
}

// With Firebase Authentication Purpose Used In This Project
class FirebaseAuthenticationRepository extends AuthenticationRepository {
  FirebaseAuthenticationRepository({
    CacheClient? cache,
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _cache = cache ?? CacheClient(),
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn() {
    // Preload Google Sign-In to speed up account chooser UI
    // _googleSignIn.signInSilently(suppressErrors: true);
  }

  final CacheClient _cache;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @visibleForTesting
  bool isWeb = kIsWeb;

  @visibleForTesting
  static const userCacheKey = '__user_cache_key__';

  Stream<User> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      final user = firebaseUser == null ? User.empty : firebaseUser.toUser;
      _cache.write(key: userCacheKey, value: user);
      return user;
    });
  }

  User get currentUser {
    return _cache.read<User>(key: userCacheKey) ?? User.empty;
  }

  Future<void> signUpWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw SignUpWithEmailAndPasswordFailure.fromCode(e.code, messageString: e.message);
    } catch (_) {
      throw const SignUpWithEmailAndPasswordFailure();
    }
  }

  Future<void> logInWithGoogle() async {
    try {
      late final firebase_auth.AuthCredential credential;
      if (isWeb) {
        // final googleProvider = firebase_auth.GoogleAuthProvider();
        final googleProvider = firebase_auth.OAuthProvider('google.com');
        final userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        credential = userCredential.credential!;
      } else {
        final googleUser = await _googleSignIn.signIn();
        final googleAuth = await googleUser!.authentication;
        credential = firebase_auth.OAuthProvider(
          'google.com',
        ).credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      }
      await _firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code, messageString: e.message);
    } catch (e) {
      debugPrint(e.toString());
      throw const LogInWithGoogleFailure();
    }
  }

  Future<void> logInWithApple() async {
    try {
      late final firebase_auth.AuthCredential credential;
      if (isWeb) {
        // final appleProvider = firebase_auth.AppleAuthProvider();
        final appleProvider = firebase_auth.OAuthProvider('apple.com');
        final userCredential = await _firebaseAuth.signInWithPopup(appleProvider);
        credential = userCredential.credential!;
      } else {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        );
        credential = firebase_auth.OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );
      }

      await _firebaseAuth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code, messageString: e.message);
    } catch (e) {
      debugPrint(e.toString());
      throw const LogInWithGoogleFailure();
    }
  }

  Future<void> logInWithPhone({required String phoneNumber}) async {
    try {
      await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
    } catch (_) {
      throw const LogInWithGoogleFailure();
    }
  }

  Future<void> logInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithEmailAndPasswordFailure.fromCode(e.code, messageString: e.message);
    } catch (_) {
      throw const LogInWithEmailAndPasswordFailure();
    }
  }

  Future<void> logOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw LogOutFailure();
    }
  }

  Future<void> deleteUser() async {
    if (_firebaseAuth.currentUser != null) {
      try {
        await _firebaseAuth.currentUser?.delete();
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw RequiresRecentLoginException();
        } else {
          throw DeleteUserFailure.fromCode(e.code, messageString: e.message);
        }
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw PasswordResetFailure.fromCode(e.code, messageString: e.message);
    }
  }

  Future<bool> checkRequiresRecentLogin() async {
    if (_firebaseAuth.currentUser != null) {
      try {
        // Try to get fresh token to check if recent login is required
        await _firebaseAuth.currentUser?.getIdToken(true);
        return false; // No recent login required
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          return true; // Recent login required
        }
        return false;
      }
    }
    return false;
  }
}

extension on firebase_auth.User {
  User get toUser {
    return User(id: uid, email: email, name: displayName, photo: photoURL);
  }
}

class SignUpWithEmailAndPasswordFailure implements Exception {
  const SignUpWithEmailAndPasswordFailure([
    this.message = 'An unknown exception occurred.',
    this.code = 'Unknown',
  ]);

  factory SignUpWithEmailAndPasswordFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      case 'invalid-email':
        return SignUpWithEmailAndPasswordFailure('Email is not valid or badly formatted.', code);
      case 'user-disabled':
        return SignUpWithEmailAndPasswordFailure(
          'This user has been disabled. Please contact support for help.',
          code,
        );
      case 'email-already-in-use':
        return SignUpWithEmailAndPasswordFailure('An account already exists for that email.', code);
      case 'operation-not-allowed':
        return SignUpWithEmailAndPasswordFailure(
          'Operation is not allowed.  Please contact support.',
          code,
        );
      case 'weak-password':
        return SignUpWithEmailAndPasswordFailure('Please enter a stronger password.', code);
      default:
        return SignUpWithEmailAndPasswordFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
  final String code;
}

class PasswordResetFailure implements Exception {
  const PasswordResetFailure([this.message = 'An unknown exception occurred.', this.code = 'Unknown']);

  factory PasswordResetFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      case 'invalid-email':
        return PasswordResetFailure('Email is not valid or badly formatted.', code);
      case 'user-not-found':
        return PasswordResetFailure('No account found with this email address.', code);
      case 'user-disabled':
        return PasswordResetFailure('This account has been disabled.', code);
      case 'too-many-requests':
        return PasswordResetFailure('Too many password reset attempts. Please try again later.', code);
      default:
        return PasswordResetFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
  final String code;
}

class LogInWithEmailAndPasswordFailure implements Exception {
  const LogInWithEmailAndPasswordFailure([this.message = 'An unknown exception occurred.']);

  factory LogInWithEmailAndPasswordFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      case 'invalid-credential':
        return const LogInWithEmailAndPasswordFailure('Wrong email or password, please try again.');
      case 'invalid-email':
        return const LogInWithEmailAndPasswordFailure('Email is not valid or badly formatted.');
      case 'user-disabled':
        return const LogInWithEmailAndPasswordFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithEmailAndPasswordFailure(
          'Email is not found, please create an account.',
        );
      case 'wrong-password':
        return const LogInWithEmailAndPasswordFailure('Incorrect password, please try again.');
      default:
        return LogInWithEmailAndPasswordFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
}

class LogInWithGoogleFailure implements Exception {
  const LogInWithGoogleFailure([this.message = 'An unknown exception occurred.']);

  factory LogInWithGoogleFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return const LogInWithGoogleFailure('Account exists with different credentials.');
      case 'invalid-credential':
        return const LogInWithGoogleFailure('The credential received is malformed or has expired.');
      case 'operation-not-allowed':
        return const LogInWithGoogleFailure('Operation is not allowed.  Please contact support.');
      case 'user-disabled':
        return const LogInWithGoogleFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithGoogleFailure('Email is not found, please create an account.');
      case 'wrong-password':
        return const LogInWithGoogleFailure('Incorrect password, please try again.');
      case 'invalid-verification-code':
        return const LogInWithGoogleFailure(
          'The credential verification code received is invalid.',
        );
      case 'invalid-verification-id':
        return const LogInWithGoogleFailure('The credential verification ID received is invalid.');
      default:
        return LogInWithGoogleFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
}

class RequiresRecentLoginException implements Exception {
  const RequiresRecentLoginException([this.message = 'Recent authentication required.']);

  final String message;
}

class DeleteUserFailure implements Exception {
  const DeleteUserFailure([this.message = 'An unknown exception occurred.', this.code = 'Unknown']);

  factory DeleteUserFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      case 'requires-recent-login':
        return DeleteUserFailure('Recent authentication required.', code);
      case 'user-not-found':
        return DeleteUserFailure('User not found.', code);
      case 'user-disabled':
        return DeleteUserFailure('This user has been disabled.', code);
      case 'operation-not-allowed':
        return DeleteUserFailure('Operation is not allowed.', code);
      default:
        return DeleteUserFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
  final String code;
}

class LogOutFailure implements Exception {
  const LogOutFailure([this.message = 'An unknown exception occurred.']);

  factory LogOutFailure.fromCode(String code, {String? messageString}) {
    switch (code) {
      default:
        return LogOutFailure(messageString ?? 'An unknown exception occurred.');
    }
  }

  final String message;
}
