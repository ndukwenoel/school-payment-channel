import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'core/offline_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_bloc.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/erp/data/erp_repository.dart';
import 'features/teacher/presentation/teacher_dashboard.dart';
// Reuse existing features
import 'features/erp/presentation/academic_dashboard_page.dart';
import 'features/erp/presentation/resource_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final offlineService = OfflineService(prefs);
  
  runApp(TeacherApp(offlineService: offlineService));
}

class TeacherApp extends StatelessWidget {
  final OfflineService offlineService;

  const TeacherApp({super.key, required this.offlineService});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authRepository = AuthRepository(apiClient);
    final erpRepository = ErpRepository(apiClient, offlineService: offlineService);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => authRepository),
        RepositoryProvider(create: (_) => erpRepository),
        RepositoryProvider(create: (_) => offlineService), // Expose valid offline service
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository)..add(AuthCheckStatus()),
        child: MaterialApp.router(
          title: 'Channel Teacher',
          theme: AppTheme.lightTheme,
          routerConfig: _router,
        ),
      ),
    );
  }

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
           // Simple auth check wrapper
           return BlocBuilder<AuthBloc, AuthState>(
             builder: (context, state) {
               if (state is AuthAuthenticated) {
                 return const TeacherDashboard();
               }
               return const LoginPage(); // Reuse main login
             },
           );
        },
      ),
      GoRoute(
        path: '/academic',
        builder: (context, state) => const AcademicDashboardPage(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const ResourceUploadPage(),
      ),
    ],
  );
}
