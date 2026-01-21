import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../data/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class AuthEvent {}
class AuthLogin extends AuthEvent {
  final String email;
  final String password;
  AuthLogin(this.email, this.password);
}
class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String role;
  AuthRegister(this.email, this.password, this.fullName, this.role);
}
class AuthLogout extends AuthEvent {}
class AuthCheckStatus extends AuthEvent {}

// States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final String role;
  final int userId;
  AuthAuthenticated(this.role, this.userId);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      final role = prefs.getString('role') ?? 'parent';
      final userId = prefs.getInt('user_id') ?? 0;
      emit(AuthAuthenticated(role, userId));
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _repository.login(event.email, event.password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', response.accessToken);
      await prefs.setInt('user_id', response.userId);
      await prefs.setString('role', response.role);
      emit(AuthAuthenticated(response.role, response.userId));
    } catch (e) {
      emit(AuthError("Login failed: ${e.toString()}"));
    }
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(event.email, event.password, event.fullName, event.role);
      // Auto login after register or ask to login? Method above returns User not AuthResponse.
      // Usually we redirect to login.
      emit(AuthError("Registration successful. Please login.")); 
      // Using AuthError to show message is a hack for MVP, better to have AuthRegistered state or similar.
    } catch (e) {
      emit(AuthError("Registration failed: ${e.toString()}"));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(AuthInitial());
  }
}
