import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_models.dart';
import '../../../core/theme.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  bool _payInFull = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildSectionLabel("PAYMENT OPTIONS"),
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
            decoration: const BoxDecoration(color: AppTheme.surfaceLight, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        const Text("INVOICE DETAILS", style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildHeroDetail() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D211A),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppTheme.limeLight, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CURRENT BALANCE DUE", style: TextStyle(color: AppTheme.limeLight, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(widget.invoice.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("\$${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
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
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text("\$${val.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
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
              color: active ? AppTheme.blueVibrant : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("OCT", style: TextStyle(fontSize: 10, opacity: 0.7)),
                Text("$day", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildOptionCard("Pay in Full", "One-time payment of \$${widget.invoice.totalAmount.toStringAsFixed(2)}", true),
        const SizedBox(height: 8),
        _buildOptionCard("Installment Plan", "4 payments of \$${(widget.invoice.totalAmount / 4).toStringAsFixed(2)} / mo", false),
      ],
    );
  }

  Widget _buildOptionCard(String title, String desc, bool value) {
    bool selected = _payInFull == value;
    return GestureDetector(
      onTap: () => setState(() => _payInFull = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.blueVibrant.withOpacity(0.1) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.blueVibrant : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.blueVibrant, width: 2)),
              child: selected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.blueVibrant, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDock() {
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
        onPressed: () => context.push('/payment-method', extra: widget.invoice),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Confirm & Pay Now"),
            Row(
              children: [
                Text("\$${widget.invoice.totalAmount.toStringAsFixed(2)}"),
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
