import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../dashboard/data/dashboard_repository.dart'; // Student
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

      if (mounted) {
        setState(() {
          _students = students;
          _invoices = invoicesMap;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildHeroCard(),
              const SizedBox(height: 16),
              _buildActionGrid(),
              const SizedBox(height: 24),
              const Text(
                "PENDING INVOICES",
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              ..._buildInvoicesList(),
              const SizedBox(height: 100), // Space for dock
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
            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5),
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
          const SizedBox(height: 8),
          Text(
            "\$${_totalOutstanding.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Due by Next Month",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(11, (index) {
              double h = [12.0, 24.0, 16.0, 32.0, 20.0, 14.0, 28.0, 10.0, 12.0, 12.0, 12.0][index];
              bool highlight = index == 3;
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: highlight ? AppTheme.blueVibrant : AppTheme.limeLight,
                  borderRadius: BorderRadius.circular(2),
                  opacity: index > 7 ? 0.3 : 0.8,
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
          child: _buildActionCard(
            title: "Download\nReceipts",
            color: AppTheme.blueVibrant,
            iconColor: Colors.white.withOpacity(0.2),
          ),
        ),
        const SizedBox(width: 8),
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
                const SizedBox(width: 3),
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

  List<Widget> _buildInvoicesList() {
    List<Widget> items = [];
    for (var list in _invoices.values) {
      for (var invoice in list) {
        if (invoice.status == 'paid') continue;
        items.add(_buildInvoiceItem(invoice));
        items.add(const SizedBox(height: 8));
      }
    }
    if (items.isEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: Text("All caught up!", style: TextStyle(color: Colors.white70))),
      ));
    }
    return items;
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
                const SizedBox(height: 2),
                Text(
                  isDueSoon ? "Due soon" : "Due ${invoice.dueDate.month}/${invoice.dueDate.day}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("\$${invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
    Invoice? firstInvoice;
    for (var list in _invoices.values) {
      for (var f in list) {
        if (f.status != 'paid') {
          firstInvoice = f;
          break;
        }
      }
      if (firstInvoice != null) break;
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
        onPressed: firstInvoice != null ? () => context.push('/invoice-detail', extra: firstInvoice) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pay Total"),
            Row(
              children: [
                Text("\$${_totalOutstanding.toStringAsFixed(2)}"),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
