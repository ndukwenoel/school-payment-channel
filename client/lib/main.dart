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
import 'features/payments/presentation/school_store_page.dart';
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
import 'features/erp/presentation/course_tests_page.dart';
import 'features/erp/presentation/test_results_entry_page.dart';
import 'features/erp/presentation/student_registry_page.dart';
import 'features/erp/presentation/staff_registry_page.dart';
import 'features/dashboard/screens/finance_dashboard_screen.dart';
import 'features/finance/presentation/general_ledger_page.dart';
import 'features/finance/data/ledger_repository.dart';
import 'features/erp/presentation/inventory_page.dart';
import 'features/erp/presentation/child_academic_view.dart';
import 'features/erp/presentation/school_profile_page.dart';
import 'features/erp/presentation/rbac_page.dart';
import 'features/erp/presentation/audit_logs_page.dart';
import 'features/erp/presentation/classrooms_page.dart';
import 'features/erp/presentation/subjects_page.dart';
import 'features/erp/presentation/attendance_page.dart';
import 'features/payments/presentation/installment_management_page.dart';
import 'features/dashboard/screens/executive_dashboard_screen.dart';
import 'features/dashboard/screens/parent_dashboard_screen.dart';
import 'features/super_admin/presentation/super_admin_dashboard.dart';
import 'features/dashboard/main_layout.dart';
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
        RepositoryProvider(create: (context) => LedgerRepository(apiClient)),
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
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final bool isAuth = authState is AuthAuthenticated;
        final bool isAuthRoute = state.matchedLocation == '/' || state.matchedLocation == '/register';

        if (!isAuth && !isAuthRoute) return '/';
        if (isAuth && isAuthRoute) {
          final role = (authState as AuthAuthenticated).role;
          if (role == 'super_admin') return '/super-admin';
          if (role == 'parent') return '/parent-dashboard';
          return '/dashboard';
        }
        return null;
      },
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
          path: '/super-admin',
          builder: (context, state) => const SuperAdminDashboard(),
        ),
        GoRoute(
          path: '/parent-dashboard',
          builder: (context, state) => const ParentDashboardScreen(),
        ),
        GoRoute(
          path: '/parent/child-academics',
          builder: (context, state) {
             final student = state.extra;
             return ChildAcademicView(student: student);
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainLayout(child: child);
          },
          routes: [
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
              path: '/store',
              builder: (context, state) => const SchoolStorePage(),
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
              path: '/erp/students',
              builder: (context, state) => const StudentRegistryPage(),
            ),
            GoRoute(
              path: '/erp/staff',
              builder: (context, state) => const StaffRegistryPage(),
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
              path: '/erp/tests',
              builder: (context, state) => const CourseTestsPage(),
            ),
            GoRoute(
              path: '/erp/tests/entry',
              builder: (context, state) {
                final test = state.extra as Map<String, dynamic>;
                return TestResultsEntryPage(test: test);
              },
            ),
            GoRoute(
              path: '/erp/review',
              builder: (context, state) => const ResourceReviewPage(),
            ),
            GoRoute(
              path: '/erp/finance',
              builder: (context, state) => const FinanceDashboardScreen(),
            ),
            GoRoute(
              path: '/erp/ledger',
              builder: (context, state) => const GeneralLedgerPage(),
            ),
            GoRoute(
              path: '/erp/inventory',
              builder: (context, state) => const InventoryPage(),
            ),
            GoRoute(
              path: '/erp/settings',
              builder: (context, state) => const SchoolProfilePage(),
            ),
            GoRoute(
              path: '/erp/rbac',
              builder: (context, state) => const RbacPage(),
            ),
            GoRoute(
              path: '/erp/audit',
              builder: (context, state) => const AuditLogsPage(),
            ),
            GoRoute(
              path: '/erp/classrooms',
              builder: (context, state) => const ClassroomsPage(),
            ),
            GoRoute(
              path: '/erp/subjects',
              builder: (context, state) => const SubjectsPage(),
            ),
            GoRoute(
              path: '/erp/attendance',
              builder: (context, state) => const AttendancePage(),
            ),
            GoRoute(
              path: '/finance/installments',
              builder: (context, state) => const InstallmentManagementPage(),
            ),
            GoRoute(
              path: '/erp/executive',
              builder: (context, state) => const ExecutiveDashboardScreen(),
            ),
          ],
        ),
      ],
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        router.refresh();
      },
      child: MaterialApp.router(
        title: 'Channel',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
