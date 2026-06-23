import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';
import 'package:go_router/go_router.dart';

class OfficeDashboardPage extends StatelessWidget {
  const OfficeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 32),
              _buildModuleGrid(context),
              SizedBox(height: 32),
              _buildSectionTitle("INVENTORY ALERTS"),
              SizedBox(height: 16),
              _buildInventoryAlerts(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("OFFICE SUITE", style: TextStyle(color: AppTheme.limeLight, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
            SizedBox(height: 4),
            const Text("Admin Control", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const Icon(Icons.settings_outlined, color: AppTheme.textMuted50),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1));
  }

  Widget _buildModuleGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildModuleCard(context, "Fee Mgmt", Icons.monetization_on_outlined, AppTheme.blueVibrant),
        _buildModuleCard(context, "Ledger", Icons.account_balance_outlined, Colors.purpleAccent),
        _buildModuleCard(context, "Payroll", Icons.payments_outlined, AppTheme.bluePale),
        _buildModuleCard(context, "Inventory", Icons.inventory_2_outlined, AppTheme.limeLight),
        _buildModuleCard(context, "Broadcasts", Icons.podcasts, Colors.orangeAccent),
        _buildModuleCard(context, "Approvals", Icons.fact_check_outlined, Colors.tealAccent),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color accent) {
    return GestureDetector(
      onTap: () {
        if (title == "Fee Mgmt") context.push('/erp/fees');
        if (title == "Ledger") context.push('/erp/ledger');
        if (title == "Payroll") context.push('/erp/payroll');
        if (title == "Inventory") context.push('/erp/inventory');
        if (title == "Reports") context.push('/erp/results');
        if (title == "Broadcasts") context.push('/erp/broadcasts');
        if (title == "Approvals") context.push('/erp/review');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 28),
            SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryAlerts(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<ErpRepository>().getInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        final lowStock = items.where((i) => i['quantity'] < 10).toList();

        if (lowStock.isEmpty) return const Text("Inventory healthy.", style: TextStyle(color: AppTheme.textMuted50));

        return Column(
          children: lowStock.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(item['name'], style: const TextStyle(fontSize: 14)),
              trailing: Text("${item['quantity']} left", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        );
      },
    );
  }
}
