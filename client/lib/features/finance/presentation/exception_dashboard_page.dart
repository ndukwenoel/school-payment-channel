import 'package:flutter/material.dart';
import '../../../core/api_client.dart';

class ExceptionDashboardPage extends StatefulWidget {
  const ExceptionDashboardPage({Key? key}) : super(key: key);

  @override
  _ExceptionDashboardPageState createState() => _ExceptionDashboardPageState();
}

class _ExceptionDashboardPageState extends State<ExceptionDashboardPage> {
  bool _isLoading = true;
  List<dynamic> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _fetchExceptions();
  }

  Future<void> _fetchExceptions() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/finance/exceptions');
      setState(() {
        _exceptions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load exceptions: $e')),
      );
    }
  }

  Future<void> _resolveException(int transactionId, String action) async {
    try {
      await ApiClient.post('/finance/resolve/$transactionId', data: {'action': action});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exception resolved successfully')),
      );
      _fetchExceptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve exception: $e')),
      );
    }
  }

  void _showResolveDialog(int transactionId, String description, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Exception'),
        content: Text('How would you like to resolve the exception for "$description" (\$$amount)?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveException(transactionId, 'refund');
            },
            child: const Text('Refund to Bank'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveException(transactionId, 'credit_wallet');
            },
            child: const Text('Credit Parent Wallet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exception Queue Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExceptions,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exceptions.isEmpty
              ? const Center(child: Text('No exceptions to review. Great job!'))
              : ListView.builder(
                  itemCount: _exceptions.length,
                  itemBuilder: (context, index) {
                    final exc = _exceptions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        title: Text(exc['description'] ?? 'Unknown Exception'),
                        subtitle: Text('Amount: \$${exc['amount']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showResolveDialog(exc['id'], exc['description'], exc['amount']),
                          child: const Text('Resolve'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
