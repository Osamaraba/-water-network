import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/employee_model.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/api_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  const AuthLoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckSession extends AuthEvent {}

class AuthBiometricRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Employee employee;
  final String token;
  const AuthAuthenticated(this.employee, this.token);
  @override
  List<Object?> get props => [employee, token];
}

class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated({this.error});
  @override
  List<Object?> get props => [error];
}

class AuthDeviceMismatch extends AuthState {
  final String message;
  const AuthDeviceMismatch(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthCheckSession>(_onCheckSession);
    on<AuthBiometricRequested>(_onBiometricAuth);
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Get device UUID
      final deviceUuid = await _deviceService.getDeviceUuid();

      // Attempt login
      final result = await _authService.login(
        username: event.username,
        password: event.password,
        deviceUuid: deviceUuid,
      );

      if (result['success'] == true) {
        final employee = Employee.fromJson(result['employee']);
        final token = result['token'] as String;

        // Verify device binding
        if (employee.deviceUuid != deviceUuid) {
          emit(const AuthDeviceMismatch(
            'هذا الحساب مرتبط بجهاز آخر. يرجى التواصل مع الإدارة.',
          ));
          return;
        }

        // Save session
        await _authService.saveSession(token, employee);
        emit(AuthAuthenticated(employee, token));
      } else {
        emit(AuthUnauthenticated(error: result['message'] ?? 'فشل تسجيل الدخول'));
      }
    } catch (e) {
      emit(AuthUnauthenticated(error: 'خطأ في الاتصال: $e'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final session = await _authService.getSession();
      if (session != null) {
        final employee = Employee.fromJson(session['employee']);
        final token = session['token'] as String;
        emit(AuthAuthenticated(employee, token));
        return;
      }
      // No saved session: log in directly with the shared universal account.
      add(const AuthLoginRequested('ENG.OR', 'ENG.OR'));
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onBiometricAuth(
    AuthBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: Implement biometric authentication
  }
}
