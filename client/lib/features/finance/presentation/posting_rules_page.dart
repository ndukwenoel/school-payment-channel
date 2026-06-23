import 'package:flutter/material.dart';
import '../../../core/api_client.dart';

class PostingRulesPage extends StatefulWidget {
  const PostingRulesPage({Key? key}) : super(key: key);

  @override
  _PostingRulesPageState createState() => _PostingRulesPageState();
}

class _PostingRulesPageState extends State<PostingRulesPage> {
  bool _isLoading = true;
  List<dynamic> _rules = [];

  final _formKey = GlobalKey<FormState>();
  String _eventType = '';
  String? _provider;
  String _debitAccount = '';
  String _creditAccount = '';

  @override
  void initState() {
    super.initState();
    _fetchRules();
  }

  Future<void> _fetchRules() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get('/finance/posting-rules');
      final data = response.data;
      setState(() {
        _rules = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posting rules: $e')),
      );
    }
  }

  Future<void> _createRule() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await ApiClient().dio.post('/finance/posting-rules', data: {
        'event_type': _eventType,
        'provider': _provider?.isEmpty ?? true ? null : _provider,
        'debit_account_name': _debitAccount,
        'credit_account_name': _creditAccount,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posting rule created successfully')),
      );
      Navigator.pop(context);
      _fetchRules();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create rule: $e')),
      );
    }
  }

  void _showAddRuleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Posting Rule'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Event Type (e.g. payment.received)'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _eventType = val!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Provider (Optional, e.g. paystack)'),
                  onSaved: (val) => _provider = val,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Debit Account Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _debitAccount = val!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Credit Account Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _creditAccount = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createRule,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Posting Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRuleDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(child: Text('No custom posting rules found. Using defaults.'))
              : ListView.builder(
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.rule, color: Colors.blue),
                        title: Text('${rule['event_type']} ${rule['provider'] != null ? '(${rule['provider']})' : ''}'),
                        subtitle: Text('DR: ${rule['debit_account_name']}\nCR: ${rule['credit_account_name']}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
