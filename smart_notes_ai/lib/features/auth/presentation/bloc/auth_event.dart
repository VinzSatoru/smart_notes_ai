import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirm;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  @override
  List<Object> get props => [name, email, password, passwordConfirm];
}

class LogoutRequested extends AuthEvent {}

class AuthRefreshUserRequested extends AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String email;
  final String name;

  const SendOtpRequested({required this.email, required this.name});

  @override
  List<Object> get props => [email, name];
}

class VerifyOtpRequested extends AuthEvent {
  final String inputOtp;
  final String expectedOtp;
  final String name;
  final String email;
  final String password;
  final String passwordConfirm;

  const VerifyOtpRequested({
    required this.inputOtp,
    required this.expectedOtp,
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  @override
  List<Object> get props => [inputOtp, expectedOtp, name, email, password, passwordConfirm];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}
