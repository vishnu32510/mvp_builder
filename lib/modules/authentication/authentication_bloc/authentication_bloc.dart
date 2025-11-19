import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
// import 'package:fact_pulse/authentication/authentication_enums.dart';
// import 'package:fact_pulse/authentication/user.dart';

import '../../../core/services/toast_service.dart';
import '../authentication_enums.dart';
import '../authentication_repository.dart';
import '../user.dart';
import '../user_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationBlocState> {
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    required UserRepository userRepository,
  }) : _authenticationRepository = authenticationRepository,
       _userRepository = userRepository,
       super(
         const AuthenticationBlocState.unknown(),
         // authenticationRepository.currentUser.isNotEmpty
         //     ? AppState.authenticated(authenticationRepository.currentUser)
         //     : const AppState.unauthenticated(),
       ) {
    on<_FirebaseAuthenticationUserChanged>(_onUserChanged);
    on<FirebaseAuthentcationLogoutRequested>(_onLogoutRequested);
    on<_CredentialAuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<CredentialAuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
    if (_authenticationRepository is FirebaseAuthenticationRepository) {
      _userSubscription = _authenticationRepository.user.listen(
        (user) => add(_FirebaseAuthenticationUserChanged(user)),
      );
    }
    if (_authenticationRepository is CredentialAuthenticationRepository) {
      _authenticationStatusSubscription = _authenticationRepository.status.listen(
        (status) => add(_CredentialAuthenticationStatusChanged(status)),
      );
    }
    on<DeleteUserRequested>(_onDeleteUserRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;
  late final StreamSubscription<User> _userSubscription;
  late StreamSubscription<AuthenticationStatus> _authenticationStatusSubscription;

  void _onUserChanged(
    _FirebaseAuthenticationUserChanged event,
    Emitter<AuthenticationBlocState> emit,
  ) {
    emit(
      event.user.isNotEmpty
          ? AuthenticationBlocState.authenticated(event.user)
          : const AuthenticationBlocState.unauthenticated(),
    );
  }

  void _onLogoutRequested(
    FirebaseAuthentcationLogoutRequested event,
    Emitter<AuthenticationBlocState> emit,
  ) {
    unawaited((_authenticationRepository as FirebaseAuthenticationRepository).logOut());
  }

  void _onDeleteUserRequested(
    DeleteUserRequested event,
    Emitter<AuthenticationBlocState> emit,
  ) async {
    try {
      // First check if recent login is required
      emit(state.copyWith(requiresRecentLogin: false));

      final requiresRecentLogin =
          await (_authenticationRepository as FirebaseAuthenticationRepository)
              .checkRequiresRecentLogin();
      if (requiresRecentLogin) {
        debugPrint('Delete user requires recent login - showing re-authentication dialog');
        // You can emit a state here to show a re-authentication dialog
        // emit(AuthenticationBlocState.requiresRecentLogin());
        emit(state.copyWith(requiresRecentLogin: true));
        // return true;
        return;
      }

             // Proceed with deletion
       await (_authenticationRepository).deleteUser();
       await (_authenticationRepository).logOut();
       
       // Show success toast
       ToastService.showSuccess('Account deleted successfully');
       debugPrint('User deleted successfully');
         } on RequiresRecentLoginException catch (e) {
       debugPrint('Delete user requires recent login: ${e.message}');
       emit(state.copyWith(requiresRecentLogin: true));
       ToastService.showWarning('Recent authentication required. Please log in again.');
     } on DeleteUserFailure catch (e) {
       debugPrint('Delete user failed: ${e.message}');
       emit(state.copyWith(requiresRecentLogin: true));
       ToastService.showError('Failed to delete account: ${e.message}');
     } catch (e) {
       debugPrint('Delete user unknown error: $e');
       emit(state.copyWith(requiresRecentLogin: true));
       ToastService.showError('Unknown error occurred during account deletion');
     }
  }

  Future<void> _onAuthenticationStatusChanged(
    _CredentialAuthenticationStatusChanged event,
    Emitter<AuthenticationBlocState> emit,
  ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        return emit(const AuthenticationBlocState.unauthenticated());
      case AuthenticationStatus.authenticated:
        final user = await _tryGetUser();
        return emit(
          user != null
              ? AuthenticationBlocState.authenticated(user)
              : const AuthenticationBlocState.unauthenticated(),
        );
      case AuthenticationStatus.unknown:
        return emit(const AuthenticationBlocState.unknown());
    }
  }

  void _onAuthenticationLogoutRequested(
    CredentialAuthenticationLogoutRequested event,
    Emitter<AuthenticationBlocState> emit,
  ) {
    (_authenticationRepository as CredentialAuthenticationRepository).logOut();
  }

  Future<User?> _tryGetUser() async {
    try {
      final user = await _userRepository.getUser();
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _authenticationStatusSubscription.cancel();
    return super.close();
  }

  // Test method to check if recent login is required
  Future<bool> checkRequiresRecentLogin() async {
    if (_authenticationRepository is FirebaseAuthenticationRepository) {
      return await (_authenticationRepository).checkRequiresRecentLogin();
    }
    return false;
  }

  void _onPasswordResetRequested(PasswordResetRequested event, Emitter<AuthenticationBlocState> emit) async {
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository).sendPasswordResetEmail(event.email);
      debugPrint('Password reset email sent successfully');
    } on PasswordResetFailure catch (e) {
      debugPrint('Password reset failed: ${e.message}');
    } catch (e) {
      debugPrint('Password reset unknown error: $e');
    }
  }
}
