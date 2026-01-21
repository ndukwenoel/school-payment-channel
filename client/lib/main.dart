import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/payments/data/payment_repository.dart';
import 'features/auth/presentation/auth_bloc.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/payments/presentation/link_student_page.dart';
import 'features/payments/presentation/fees_list_page.dart';
import 'features/payments/presentation/payment_history_page.dart';
import 'features/dashboard/presentation/create_fee_page.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/notification_history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authRepository = AuthRepository(apiClient);
    final dashboardRepository = DashboardRepository(apiClient);
    final paymentRepository = PaymentRepository(apiClient);
    final notificationRepository = NotificationRepository(apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => authRepository),
        RepositoryProvider(create: (context) => dashboardRepository),
        RepositoryProvider(create: (context) => paymentRepository),
        RepositoryProvider(create: (context) => notificationRepository),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository)..add(AuthCheckStatus()),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine initial route based on auth state? 
    // Actually GoRouter redirect is better but for MVP simple conditional or initial route logic.
    // Let's use a simple router definition.
    
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/create-fee',
          builder: (context, state) => const CreateFeePage(),
        ),
        GoRoute(
          path: '/link-student',
          builder: (context, state) => const LinkStudentPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationHistoryPage(),
        ),
        GoRoute(
          path: '/fees',
          builder: (context, state) => const FeesListPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const PaymentHistoryPage(),
        ),
      ],
      redirect: (context, state) {
        // Redirection logic can be added here to protect /dashboard
        // For now relying on Login page navigation
        return null;
      },
    );



class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      // ... routes as is ...
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/create-fee',
          builder: (context, state) => const CreateFeePage(),
        ),
        GoRoute(
          path: '/link-student',
          builder: (context, state) => const LinkStudentPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationHistoryPage(),
        ),
        GoRoute(
          path: '/fees',
          builder: (context, state) => const FeesListPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const PaymentHistoryPage(),
        ),
      ],
      redirect: (context, state) {
        return null;
      },
    );

    return MaterialApp.router(
      title: 'School Payment',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

