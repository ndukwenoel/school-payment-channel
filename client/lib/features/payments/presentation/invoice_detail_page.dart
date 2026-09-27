import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../auth/presentation/auth_bloc.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  bool _isAdmin = false;
  bool _loadingAdmin = false;
  Map<String, dynamic>? _adminDetails;

  // Offline Payment Form State (Admin)
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedMethod = 'cash';
  bool _submittingPayment = false;
  bool _sendingReminder = false;
  bool _voiding = false;

  // Parent State
  int _selectedInstallmentCount = 1;
  List<int> _allowedOptions = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndLoad() async {
    final authState = context.read<AuthBloc>().state;
    final bool isAdminRole = authState is AuthAuthenticated && authState.role != 'parent';

    setState(() {
      _isAdmin = isAdminRole;
    });

    if (isAdminRole) {
      await _fetchAdminDetails();
    } else {
      await _fetchSchoolConfig();
    }
  }

  Future<void> _fetchAdminDetails() async {
    setState(() => _loadingAdmin = true);
    try {
      final repo = context.read<PaymentRepository>();
      final data = await repo.getInvoiceDetails(widget.invoice.id);
      if (mounted) {
        setState(() {
          _adminDetails = data;
          _loadingAdmin = false;
          final double outstanding = (data['amount_outstanding'] as num?)?.toDouble() ?? 0.0;
          _amountController.text = outstanding.toStringAsFixed(2);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAdmin = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load invoice: $e")));
      }
    }
  }

  Future<void> _fetchSchoolConfig() async {
    try {
      final api = ApiClient();
      final res = await api.dio.get('/api/v1/schools/me');
      final optionsStr = res.data['allowed_installment_options'] as String?;
      if (optionsStr != null && optionsStr.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allowedOptions = optionsStr.split(',').map((e) => int.tryParse(e.trim()) ?? 4).where((e) => e > 1).toList();
            _allowedOptions.sort();
            _isLoadingOptions = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoadingOptions = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingOptions = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return _buildAdminView();
    } else {
      return _buildParentView();
    }
  }

  // =========================================================================
  // ADMIN CONSOLE: INVOICE MANAGEMENT & BURSAR DESK
  // =========================================================================

  Widget _buildAdminView() {
    if (_loadingAdmin && _adminDetails == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _adminDetails ?? {};
    final String title = data['title'] ?? widget.invoice.title;
    final String status = data['status'] ?? widget.invoice.status;
    final double totalAmount = (data['total_amount'] as num?)?.toDouble() ?? widget.invoice.totalAmount;
    final double amountPaid = (data['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final double amountOutstanding = (data['amount_outstanding'] as num?)?.toDouble() ?? (totalAmount - amountPaid);
    final String studentName = data['student_name'] ?? widget.invoice.studentName ?? "Student #${widget.invoice.studentId}";
    final String enrollmentNumber = data['enrollment_number'] ?? widget.invoice.enrollmentNumber ?? "No Reg #";
    final String grade = data['student_grade'] ?? "N/A";
    final String parentName = data['parent_name'] ?? "Not Registered";
    final String parentEmail = data['parent_email'] ?? "No Email";
    final String parentPhone = data['parent_phone'] ?? "No Phone";
    final List<dynamic> lineItems = data['line_items'] ?? [];
    final List<dynamic> payments = data['payment_attempts'] ?? [];

    DateTime dueDate = widget.invoice.dueDate;
    if (data['due_date'] != null) {
      try {
        dueDate = DateTime.parse(data['due_date']);
      } catch (_) {}
    }

    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action / Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                        tooltip: "Back to Invoices",
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text("INV-${widget.invoice.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textDark)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: _sendingReminder
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined, size: 16),
                        label: const Text("Send Reminder"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: (status == 'paid' || status == 'voided' || _sendingReminder) ? null : _sendReminder,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                        label: const Text("Official Statement", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showPrintReceiptDialog,
                      ),
                      if (status != 'paid' && status != 'voided') ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: _voiding
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error))
                              : const Icon(Icons.block, color: AppTheme.error),
                          tooltip: "Void Invoice",
                          onPressed: _voiding ? null : _confirmVoidInvoice,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Row
              Row(
                children: [
                  _buildMetricCard(
                    title: "TOTAL INVOICE",
                    amount: "₦${totalAmount.toStringAsFixed(2)}",
                    subtext: "${lineItems.length} line item(s)",
                    color: AppTheme.primaryBlue,
                    icon: Icons.receipt_outlined,
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    title: "AMOUNT PAID",
                    amount: "₦${amountPaid.toStringAsFixed(2)}",
                    subtext: totalAmount > 0 ? "${((amountPaid / totalAmount) * 100).toStringAsFixed(1)}% settled" : "Settled",
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    title: "OUTSTANDING BALANCE",
                    amount: "₦${amountOutstanding.toStringAsFixed(2)}",
                    subtext: "Due by ${DateFormat('MMM dd, yyyy').format(dueDate)}",
                    color: amountOutstanding > 0 ? AppTheme.warning : AppTheme.success,
                    icon: Icons.pending_actions_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2-Column Responsive Body
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 850;
                  final leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentParentDossier(studentName, enrollmentNumber, grade, parentName, parentEmail, parentPhone),
                      const SizedBox(height: 20),
                      _buildLineItemsCard(lineItems, totalAmount),
                      const SizedBox(height: 20),
                      _buildPaymentAuditTrail(payments),
                    ],
                  );

                  final rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBursarDeskCard(status, amountOutstanding),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: leftColumn),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: rightColumn),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        leftColumn,
                        const SizedBox(height: 24),
                        rightColumn,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtext, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentParentDossier(String studentName, String regNo, String grade, String parentName, String email, String phone) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text("STUDENT & GUARDIAN PROFILE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("STUDENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(studentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                          child: Text(regNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        Text("Class: $grade", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 50, width: 1, color: AppTheme.textMuted.withOpacity(0.15)),
              const SizedBox(width: 20),
              // Guardian Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GUARDIAN / PAYER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(parentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Flexible(child: Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard(List<dynamic> lineItems, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_list_bulleted, size: 18, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  const Text("ITEMIZED FEE BREAKDOWN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                ],
              ),
              Text("${lineItems.length} components", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          const Divider(height: 24),
          if (lineItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text("No line items attached to this invoice.", style: TextStyle(color: AppTheme.textMuted))),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text("FEE COMPONENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                  Expanded(flex: 1, child: Text("AMOUNT", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...lineItems.map((item) {
              final itemTitle = item['title'] ?? 'Component';
              final double itemAmt = (item['amount'] as num?)?.toDouble() ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(itemTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark))),
                    Expanded(flex: 1, child: Text("₦${itemAmt.toStringAsFixed(2)}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL INVOICE AMOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  Text("₦${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentAuditTrail(List<dynamic> payments) {
    final successfulPayments = payments.where((p) => p['status'] == 'success').toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 18, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  const Text("PAYMENT AUDIT TRAIL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                ],
              ),
              Text("${successfulPayments.length} recorded", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          const Divider(height: 24),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text("No payment attempts or receipts logged for this invoice yet.", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
            )
          else
            ...payments.map((p) {
              final double pAmt = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final String provider = (p['provider'] as String? ?? 'offline').toUpperCase();
              final String ref = p['transaction_id'] ?? "No Ref";
              final String pStatus = p['status'] ?? 'pending';
              DateTime pDate = DateTime.now();
              if (p['payment_date'] != null) {
                try { pDate = DateTime.parse(p['payment_date']); } catch (_) {}
              }

              final isSuccess = pStatus == 'success';
              final badgeColor = isSuccess ? AppTheme.success : AppTheme.warning;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.contains('CASH') ? Icons.payments_outlined : (provider.contains('POS') ? Icons.point_of_sale : Icons.credit_card),
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(provider, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark)),
                              const SizedBox(width: 6),
                              Text("• $ref", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(DateFormat('MMM dd, yyyy HH:mm').format(pDate), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₦${pAmt.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(pStatus.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBursarDeskCard(String status, double outstanding) {
    if (status == 'paid') {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified, color: AppTheme.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text("INVOICE FULLY CLEARED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            const Text("All component line items have been settled in full. No balance remains outstanding.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 16, color: Colors.white),
              label: const Text("Print Official Receipt", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              onPressed: _showPrintReceiptDialog,
            ),
          ],
        ),
      );
    }

    if (status == 'voided') {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.block, color: AppTheme.error, size: 40),
            SizedBox(height: 12),
            Text("INVOICE VOIDED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error)),
            SizedBox(height: 4),
            Text("This invoice has been revoked by administration. Payments cannot be posted against voided invoices.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    // Active Bursar Posting Form
    final methods = [
      {'key': 'cash', 'label': 'Cash', 'icon': Icons.payments_outlined},
      {'key': 'pos', 'label': 'School POS', 'icon': Icons.point_of_sale},
      {'key': 'bank_transfer', 'label': 'Bank Deposit', 'icon': Icons.account_balance},
      {'key': 'cheque', 'label': 'Cheque', 'icon': Icons.edit_note},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.point_of_sale, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BURSAR DESK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  Text("Record Offline Payment", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // Quick fill chips
          const Text("QUICK FILL AMOUNT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              ActionChip(
                label: Text("Full: ₦${outstanding.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.08),
                onPressed: () => setState(() => _amountController.text = outstanding.toStringAsFixed(2)),
              ),
              const SizedBox(width: 8),
              if (outstanding > 100)
                ActionChip(
                  label: Text("Half: ₦${(outstanding / 2).toStringAsFixed(0)}", style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.background,
                  onPressed: () => setState(() => _amountController.text = (outstanding / 2).toStringAsFixed(2)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount Field
          const Text("PAYMENT AMOUNT (₦)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: "₦ ",
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          // Payment Channel Chips
          const Text("PAYMENT CHANNEL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: methods.map((m) {
              final isSelected = _selectedMethod == m['key'];
              return ChoiceChip(
                avatar: Icon(m['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppTheme.textDark),
                label: Text(m['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.textDark)),
                selected: isSelected,
                selectedColor: AppTheme.primaryBlue,
                backgroundColor: AppTheme.background,
                onSelected: (val) {
                  if (val) setState(() => _selectedMethod = m['key'] as String);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Reference Number
          const Text("BURSAR RECEIPT / SLIP #", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _refController,
            decoration: InputDecoration(
              hintText: "e.g. POS-9842 or CASH-REC-012",
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          // Notes
          const Text("INTERNAL NOTES (OPTIONAL)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "e.g. Paid in-person at finance desk by mother",
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              icon: _submittingPayment
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle, size: 18, color: Colors.white),
              label: Text(
                _submittingPayment ? "Processing..." : "Post Payment & Update Ledger",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submittingPayment ? null : _submitOfflinePayment,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOfflinePayment() async {
    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid payment amount.')));
      return;
    }

    setState(() => _submittingPayment = true);
    try {
      final repo = context.read<PaymentRepository>();
      final updated = await repo.recordOfflinePayment(
        invoiceId: widget.invoice.id,
        amount: amount,
        paymentMethod: _selectedMethod,
        reference: _refController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _adminDetails = updated;
          _submittingPayment = false;
          _notesController.clear();
          _refController.clear();
          final double outstanding = (updated['amount_outstanding'] as num?)?.toDouble() ?? 0.0;
          _amountController.text = outstanding.toStringAsFixed(2);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Payment of ₦${amount.toStringAsFixed(2)} successfully posted!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submittingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to record payment: $e')));
      }
    }
  }

  Future<void> _sendReminder() async {
    setState(() => _sendingReminder = true);
    try {
      final repo = context.read<PaymentRepository>();
      await repo.sendInvoiceReminder(widget.invoice.id);
      if (mounted) {
        setState(() => _sendingReminder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Payment reminder dispatched to parent successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingReminder = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reminder: $e')));
      }
    }
  }

  Future<void> _confirmVoidInvoice() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Invoice?'),
        content: Text('Are you sure you want to void invoice INV-${widget.invoice.id}? This will cancel all pending balances for this student.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void Invoice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _voiding = true);
    try {
      final repo = context.read<PaymentRepository>();
      await repo.voidInvoice(widget.invoice.id);
      if (mounted) {
        setState(() => _voiding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as voided.')),
        );
        _fetchAdminDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _voiding = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showPrintReceiptDialog() {
    final data = _adminDetails ?? {};
    final title = data['title'] ?? widget.invoice.title;
    final studentName = data['student_name'] ?? widget.invoice.studentName ?? 'Student #${widget.invoice.studentId}';
    final regNo = data['enrollment_number'] ?? widget.invoice.enrollmentNumber ?? 'N/A';
    final grade = data['student_grade'] ?? 'N/A';
    final total = (data['total_amount'] as num?)?.toDouble() ?? widget.invoice.totalAmount;
    final paid = (data['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final outstanding = (data['amount_outstanding'] as num?)?.toDouble() ?? (total - paid);
    final status = (data['status'] as String?) ?? widget.invoice.status;
    final lineItems = (data['line_items'] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 28),
                SizedBox(width: 10),
                Text("Official Fee Statement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.textMuted.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CHANNEL EDUCATION SYSTEMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text("Invoice Ref: INV-${widget.invoice.id} • $title", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(status))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text("STUDENT: $studentName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                const SizedBox(height: 4),
                Text("Reg No: $regNo  •  Class: $grade", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const Divider(height: 24),
                const Text("LINE ITEMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                if (lineItems.isEmpty)
                  const Text("No line items", style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
                else
                  ...lineItems.map((li) {
                    final itemTitle = li['title'] ?? 'Item';
                    final itemAmt = (li['amount'] as num?)?.toDouble() ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(itemTitle, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                          Text("₦${itemAmt.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Billed:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text("₦${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Paid:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.success)),
                    Text("₦${paid.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.success)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Outstanding Balance:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.error)),
                    Text("₦${outstanding.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.error)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            icon: const Icon(Icons.print, size: 18, color: Colors.white),
            label: const Text("Print / Save PDF", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt document sent to system print dialog.')));
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return AppTheme.success;
      case 'pending': return AppTheme.warning;
      case 'partial': return Colors.purple;
      case 'overdue': return AppTheme.error;
      case 'voided': return AppTheme.textMuted;
      default: return AppTheme.textMuted;
    }
  }

  // =========================================================================
  // PARENT VIEW: CONSUMER CHECKOUT & INSTALLMENT PLAN
  // =========================================================================

  Widget _buildParentView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavHeader(context),
              const SizedBox(height: 16),
              _buildHeroDetail(),
              const SizedBox(height: 24),
              _buildSectionLabel("COMPONENT BREAKDOWN"),
              _buildBreakdownCard(),
              const SizedBox(height: 24),
              _buildSectionLabel("PAYMENT DEADLINE"),
              _buildCalendarStrip(),
              const SizedBox(height: 24),
              _buildPaymentOptions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildPaymentDock(),
    );
  }

  Widget _buildNavHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppTheme.cardBackground, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppTheme.textDark),
          ),
        ),
        const SizedBox(width: 16),
        const Text("INVOICE DETAILS", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildHeroDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CURRENT BALANCE DUE", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.invoice.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("₦${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: widget.invoice.lineItems.map((item) {
          return _buildBreakdownRow(item.title, item.amount);
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          Text("₦${val.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(6, (index) {
          int day = widget.invoice.dueDate.day - 3 + index;
          bool active = day == widget.invoice.dueDate.day;
          return Container(
            width: 60,
            height: 70,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryBlue : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.textMuted.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(widget.invoice.dueDate).toUpperCase(),
                  style: TextStyle(fontSize: 10, color: active ? Colors.white70 : AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
                Text("$day", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: active ? Colors.white : AppTheme.textDark)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.schedule, color: AppTheme.primaryBlue),
            label: const Text("Need an installment plan? Request here", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            onPressed: _showCustomPlanDialog,
          ),
        ),
      ],
    );
  }

  Future<void> _showCustomPlanDialog() async {
    final reasonController = TextEditingController();
    List<int> allowedOptions = _allowedOptions.isNotEmpty ? _allowedOptions : [2, 3, 4];
    int numInstallments = allowedOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Request Payment Plan", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Number of Installments:"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: allowedOptions.map((opt) {
                        return ChoiceChip(
                          label: Text("$opt installments"),
                          selected: numInstallments == opt,
                          onSelected: (selected) {
                            if (selected) setState(() => numInstallments = opt);
                          },
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(color: numInstallments == opt ? Colors.white : AppTheme.textDark),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Reason for Request (Optional):"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: "e.g. Financial hardship, staggered salary",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Approx ₦${(widget.invoice.totalAmount / numInstallments).toStringAsFixed(2)} per installment",
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  onPressed: () async {
                    final reason = reasonController.text;
                    Navigator.pop(context);
                    await _submitPlanRequest(numInstallments, reason);
                  },
                  child: const Text("Submit Request", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPlanRequest(int count, String reason) async {
    try {
      final repo = context.read<PaymentRepository>();
      double perInst = widget.invoice.totalAmount / count;
      List<Map<String, dynamic>> proposed = [];
      DateTime now = DateTime.now();
      for (int i = 0; i < count; i++) {
        proposed.add({
          "amount": perInst,
          "due_date": now.add(Duration(days: 30 * (i + 1))).toIso8601String(),
        });
      }

      await repo.requestPaymentPlan(widget.invoice.id, proposed, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment plan request sent for administrative review.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildPaymentDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          context.push('/payment-method', extra: widget.invoice);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pay Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Row(
              children: [
                Text("₦${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
