import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../dashboard/data/dashboard_repository.dart'; // Student
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_models.dart' as auth;
import '../../../core/theme.dart';

class InvoicesListPage extends StatefulWidget {
  const InvoicesListPage({super.key});

  @override
  State<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends State<InvoicesListPage> {
  bool _loading = true;
  List<Student> _students = [];
  Map<int, List<Invoice>> _invoices = {};
  final Set<int> _processingInvoices = {};
  auth.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<PaymentRepository>();
      final students = await repo.getMyStudents();
      Map<int, List<Invoice>> invoicesMap = {};
      
      for (var s in students) {
        final invoices = await repo.getStudentInvoices(s.id);
        invoicesMap[s.id] = invoices;
      }
      
      final authRepo = context.read<AuthRepository>();
      final user = await authRepo.getCurrentUser();

      if (mounted) {
        setState(() {
          _students = students;
          _invoices = invoicesMap;
          _currentUser = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  double get _totalOutstanding {
    double total = 0;
    for (var list in _invoices.values) {
      for (var i in list) {
        if (i.status != 'paid') total += i.totalAmount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16),
                    _buildHeroCard(),
                    SizedBox(height: 16),
                    _buildActionGrid(),
                    SizedBox(height: 24),
                    if (_currentUser != null) _buildCreditBalanceCard(),
                    if (_currentUser != null) SizedBox(height: 24),
                  ],
                ),
              ),
              const TabBar(
                labelColor: AppTheme.limeLight,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.limeLight,
                tabs: [
                  Tab(text: "Pending"),
                  Tab(text: "Partial"),
                  Tab(text: "Paid"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTabContent('pending'),
                    _buildTabContent('partial'),
                    _buildTabContent('paid'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _totalOutstanding > 0 ? _buildPaymentDock() : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "FINANCE PORTAL",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 0.5),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.limeLight,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.voidBlack, width: 2),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.greenDeep,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL OUTSTANDING",
            style: TextStyle(color: AppTheme.limeLight, fontSize: 11, letterSpacing: 0.5),
          ),
          SizedBox(height: 8),
          Text(
            "?${_totalOutstanding.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          const Text(
            "Due by Next Month",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(11, (index) {
              double h = [12.0, 24.0, 16.0, 32.0, 20.0, 14.0, 28.0, 10.0, 12.0, 12.0, 12.0][index];
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withOpacity(index > 7 ? 0.3 : 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/store'),
            child: _buildActionCard(
              title: "School\nStore",
              color: AppTheme.sageGreen,
              textColor: AppTheme.textDark,
              iconColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildActionCard(
            title: "Download\nReceipts",
            color: AppTheme.blueVibrant,
            iconColor: Colors.white.withOpacity(0.2),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/history'),
            child: _buildActionCard(
              title: "Payment\nHistory",
              color: AppTheme.bluePale,
              textColor: Colors.black,
              iconColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required Color color, Color textColor = Colors.white, required Color iconColor}) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.5), shape: BoxShape.circle)),
                SizedBox(width: 3),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.5), shape: BoxShape.circle)),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: textColor, shape: BoxShape.circle))),
          ),
          Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildCreditBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppTheme.blueVibrant, size: 20),
                  SizedBox(width: 8),
                  const Text("CREDIT BALANCE", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5)),
                ],
              ),
              ElevatedButton(
                onPressed: _showTopUpDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueVibrant.withOpacity(0.1),
                  foregroundColor: AppTheme.blueVibrant,
                  elevation: 0,
                  minimumSize: const Size(60, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text("TOP UP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "₦${_currentUser!.creditBalance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.05)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Auto-Pay Future Invoices", style: TextStyle(fontSize: 14)),
              Switch(
                value: _currentUser!.autoPayEnabled,
                onChanged: (val) => _toggleAutoPay(),
                activeColor: AppTheme.limeLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleAutoPay() async {
    try {
      final repo = context.read<PaymentRepository>();
      final result = await repo.toggleAutoPay();
      setState(() {
         // Optimistically update
         // Need a way to mutate User or just reload
      });
      await _loadData(); // Reload user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Top Up Balance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter amount to add to your credit balance. In a real app, this would open Paystack/Flutterwave.", style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₦)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text);
              if (amt != null && amt > 0) {
                Navigator.pop(ctx);
                try {
                  setState(() => _loading = true);
                  final repo = context.read<PaymentRepository>();
                  await repo.topUpWallet(amt, "TOPUP-${DateTime.now().millisecondsSinceEpoch}");
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Top-up successful!")));
                } catch (e) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Top Up"),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String filterStatus) {
    List<Widget> items = [];
    for (var list in _invoices.values) {
      for (var invoice in list) {
        if (filterStatus == 'pending' && invoice.status != 'pending') continue;
        if (filterStatus == 'partial' && invoice.status != 'partial') continue;
        if (filterStatus == 'paid' && invoice.status != 'paid') continue;
        
        items.add(_buildInvoiceItem(invoice));
      }
    }
    if (items.isEmpty) {
      return Center(child: Text("No $filterStatus invoices found.", style: const TextStyle(color: AppTheme.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildInvoiceItem(Invoice invoice) {
    bool isDueSoon = invoice.dueDate.difference(DateTime.now()).inDays < 7;
    return GestureDetector(
      onTap: () => context.push('/invoice-detail', extra: invoice),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDueSoon ? const Color(0xFF0D211A) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: isDueSoon ? AppTheme.limeLight : AppTheme.blueVibrant, width: 4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                SizedBox(height: 2),
                Text(
                  isDueSoon ? "Due soon" : "Due ${invoice.dueDate.month}/${invoice.dueDate.day}",
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("?${invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                if (isDueSoon)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("UNPAID", style: TextStyle(color: AppTheme.limeLight, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDock() {
    List<int> unpaidInvoiceIds = [];
    for (var list in _invoices.values) {
      for (var f in list) {
        if (f.status != 'paid') {
          unpaidInvoiceIds.add(f.id);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppTheme.voidBlack, AppTheme.voidBlack.withOpacity(0)],
          stops: const [0.8, 1.0],
        ),
      ),
      child: ElevatedButton(
        onPressed: unpaidInvoiceIds.isNotEmpty ? () => _handlePayTotal(unpaidInvoiceIds) : null,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeLight, foregroundColor: Colors.black),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pay Total (Consolidated)"),
            Row(
              children: [
                Text("₦${_totalOutstanding.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayTotal(List<int> invoiceIds) async {
    setState(() => _loading = true);
    try {
      final repo = context.read<PaymentRepository>();
      final bundle = await repo.createPaymentBundle(invoiceIds);
      
      if (mounted) {
        setState(() => _loading = false);
        _showBundleTransferDialog(bundle['reference'], bundle['total_amount']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating bundle: $e")));
      }
    }
  }

  void _showBundleTransferDialog(String reference, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Consolidated Payment Bundle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("To clear all your outstanding invoices with a single payment, please transfer the exact total below:"),
            SizedBox(height: 16),
            Text("Total Amount: ₦${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.limeLight)),
            SizedBox(height: 16),
            const Text("Bank: Opay", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Account Name: School Payment Gateway", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Account No: 1234567890", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.blueVibrant)),
            SizedBox(height: 16),
            const Text("IMPORTANT: You must use the exact reference code below as your transfer description/narration. This ensures automatic splitting and reconciliation.", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: Text(reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Optimistically reload to see pending attempts? 
              // Wait, bundles create pending attempts immediately. We could refresh.
              _loadData();
            },
            child: const Text("I have transferred"),
          ),
        ],
      ),
    );
  }
}
