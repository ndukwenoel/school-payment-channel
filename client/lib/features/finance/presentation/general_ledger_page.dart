import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/ledger_repository.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';

class GeneralLedgerPage extends StatefulWidget {
  const GeneralLedgerPage({super.key});

  @override
  State<GeneralLedgerPage> createState() => _GeneralLedgerPageState();
}

class _GeneralLedgerPageState extends State<GeneralLedgerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  List<dynamic> _accounts = [];
  List<dynamic> _transactions = [];
  List<dynamic> _rules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<LedgerRepository>();
      final accounts = await repo.getAccounts();
      final transactions = await repo.getTransactions();
      final rules = await repo.getPostingRules();
      
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _transactions = transactions;
          _rules = rules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading ledger: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('General Ledger'),
        backgroundColor: AppTheme.voidBlack,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.limeLight,
          unselectedLabelColor: AppTheme.textMuted50,
          indicatorColor: AppTheme.limeLight,
          tabs: const [
            Tab(text: 'Chart of Accounts'),
            Tab(text: 'Journal Entries'),
            Tab(text: 'Posting Rules'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsTab(),
                _buildJournalTab(),
                _buildRulesTab(),
              ],
            ),
    );
  }

  Widget _buildAccountsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final acc = _accounts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.bluePale.withOpacity(0.2),
              child: const Icon(Icons.account_balance_wallet, color: AppTheme.blueVibrant),
            ),
            title: Text(acc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(acc['type'].toString().toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Text(
              '₦${(acc['balance'] as num).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: (acc['balance'] as num) < 0 ? Colors.red : Colors.green[700],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJournalTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final txn = _transactions[index];
        final date = DateTime.parse(txn['created_at']).toLocal();
        final entries = txn['entries'] as List<dynamic>;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(txn['description'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Text(DateFormat('MMM dd, HH:mm').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const Divider(),
                const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Credit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),
                ...entries.map((entry) {
                  final isDebit = entry['type'] == 'debit';
                  final amount = (entry['amount'] as num).toStringAsFixed(2);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(entry['account']['name'], style: TextStyle(color: Colors.grey[800]))),
                        Expanded(flex: 1, child: Text(isDebit ? amount : '-', textAlign: TextAlign.right)),
                        Expanded(flex: 1, child: Text(!isDebit ? amount : '-', textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(rule['event_type'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rule['provider'] != null) Text('Provider: ${rule['provider']}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('DR: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(rule['debit_account_name'], style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    const Text('CR: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(rule['credit_account_name'], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
