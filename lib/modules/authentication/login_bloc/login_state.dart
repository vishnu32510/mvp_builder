part of 'login_bloc.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.status = FormzSubmissionStatus.initial,
    this.username = "",
    this.phone = "",
    this.password = "",
    this.isValid = true,
    this.errorMessage,
  });

  final FormzSubmissionStatus status;
  final String username;
  final String phone;
  final String password;
  final bool isValid;
  final String? errorMessage;

  LoginState copyWith({
    FormzSubmissionStatus? status,
    String? username,
    String? phone,
    String? password,
    bool? isValid,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, username, password,isValid,username,phone];
}