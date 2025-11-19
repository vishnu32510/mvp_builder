part of 'authentication_bloc.dart';

final class AuthenticationBlocState extends Equatable {
  const AuthenticationBlocState._({
    required this.status,
    this.user = User.empty,
    this.requiresRecentLogin = false,
  });

  const AuthenticationBlocState.unknown() : this._(status: AuthenticationStatus.unknown, requiresRecentLogin: false);

  const AuthenticationBlocState.authenticated(User user, {bool? requiresRecentLogin})
    : this._(
        status: AuthenticationStatus.authenticated,
        user: user,
        requiresRecentLogin: requiresRecentLogin ?? false,
      );

  const AuthenticationBlocState.unauthenticated()
    : this._(status: AuthenticationStatus.unauthenticated,requiresRecentLogin: false);


  //Copy with
  AuthenticationBlocState copyWith({
    AuthenticationStatus? status,
    User? user,
    bool? requiresRecentLogin,
  }) {
    return AuthenticationBlocState._(
      status: status ?? this.status,
      user: user ?? this.user,
      requiresRecentLogin: requiresRecentLogin ?? this.requiresRecentLogin,
    );
  }

  final AuthenticationStatus status;
  final User user;
  final bool requiresRecentLogin;

  @override
  List<Object> get props => [status, user, requiresRecentLogin];
}
