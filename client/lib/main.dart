import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/payments/data/payment_repository.dart';
import 'features/auth/presentation/auth_bloc.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/payments/presentation/link_student_page.dart';
import 'features/payments/presentation/invoices_list_page.dart';
import 'features/payments/presentation/invoice_detail_page.dart';
import 'features/payments/presentation/payment_method_page.dart';
import 'features/payments/presentation/payment_success_page.dart';
import 'features/payments/data/payment_models.dart';
import 'features/notifications/presentation/notification_history_page.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/erp/data/erp_repository.dart';
import 'features/erp/presentation/academic_dashboard_page.dart';
import 'features/erp/presentation/office_dashboard_page.dart';
import 'features/erp/presentation/fee_management_page.dart';
import 'features/erp/presentation/payroll_page.dart';
import 'features/erp/presentation/results_page.dart';
import 'features/erp/presentation/broadcast_page.dart';
import 'features/erp/presentation/resource_pages.dart';
import 'features/dashboard/screens/finance_dashboard_screen.dart';
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
        RepositoryProvider(create: (context) => ErpRepository(apiClient)),
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
          path: '/link-student',
          builder: (context, state) => const LinkStudentPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationHistoryPage(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoicesListPage(),
        ),
        GoRoute(
          path: '/invoice-detail',
          builder: (context, state) {
            final invoice = state.extra as Invoice;
            return InvoiceDetailPage(invoice: invoice);
          },
        ),
        GoRoute(
          path: '/payment-method',
          builder: (context, state) {
            final invoice = state.extra as Invoice;
            return PaymentMethodPage(invoice: invoice);
          },
        ),
        GoRoute(
          path: '/payment-success',
          builder: (context, state) {
            final invoice = state.extra as Invoice;
            return PaymentSuccessPage(invoice: invoice);
          },
        ),
        GoRoute(
          path: '/erp/academic',
          builder: (context, state) => const AcademicDashboardPage(),
        ),
        GoRoute(
          path: '/erp/office',
          builder: (context, state) => const OfficeDashboardPage(),
        ),
        GoRoute(
          path: '/erp/fees',
          builder: (context, state) => const FeeManagementPage(),
        ),
        GoRoute(
          path: '/erp/payroll',
          builder: (context, state) => const PayrollPage(),
        ),
        GoRoute(
          path: '/erp/results',
          builder: (context, state) => const ResultsPage(),
        ),
        GoRoute(
          path: '/erp/broadcasts',
          builder: (context, state) => const BroadcastPage(),
        ),
        GoRoute(
          path: '/erp/upload',
          builder: (context, state) => const ResourceUploadPage(),
        ),
        GoRoute(
          path: '/erp/review',
          builder: (context, state) => const ResourceReviewPage(),
        ),
        GoRoute(
          path: '/erp/finance',
          builder: (context, state) => const FinanceDashboardScreen(),
        ),
      ],
      redirect: (context, state) {
        // Redirection logic can be added here to protect /dashboard
        // For now relying on Login page navigation
        return null;
      },
    );

    return MaterialApp.router(
      title: 'Channel',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
