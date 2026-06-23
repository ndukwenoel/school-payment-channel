import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailPage({super.key, required this.invoice});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  int _selectedInstallmentCount = 1; // 1 = full payment
  List<int> _allowedOptions = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _fetchSchoolConfig();
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavHeader(context),
              SizedBox(height: 16),
              _buildHeroDetail(),
              SizedBox(height: 24),
              _buildSectionLabel("COMPONENT BREAKDOWN"),
              _buildBreakdownCard(),
              SizedBox(height: 24),
              _buildSectionLabel("PAYMENT DEADLINE"),
              _buildCalendarStrip(),
              SizedBox(height: 24),
              _buildPaymentOptions(),
              SizedBox(height: 100),
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
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppTheme.textDark),
          ),
        ),
        SizedBox(width: 16),
        const Text("INVOICE DETAILS", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 0.5)),
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
          SizedBox(height: 4),
          Text(widget.invoice.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("₦${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5)),
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
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          Text("₦${val.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
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
                const Text("OCT", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                Text("$day", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    if (_isLoadingOptions) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TextButton(
            onPressed: _showCustomPlanDialog,
            child: const Text("Need an installment plan? Request here", style: TextStyle(color: AppTheme.blueVibrant)),
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
              title: const Text("Request Payment Plan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Number of Installments:"),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: allowedOptions.map((opt) {
                        return ChoiceChip(
                          label: Text("$opt"),
                          selected: numInstallments == opt,
                          onSelected: (selected) {
                            if (selected) setState(() => numInstallments = opt);
                          },
                          selectedColor: AppTheme.blueVibrant,
                          labelStyle: TextStyle(color: numInstallments == opt ? Colors.white : AppTheme.textDark),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    const Text("Reason for Request (Optional):"),
                    SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: "e.g. Financial hardship, multiple children",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Text("Approx ₦${(widget.invoice.totalAmount / numInstallments).toStringAsFixed(2)} per installment", style: const TextStyle(color: AppTheme.limeLight)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    final reason = reasonController.text;
                    Navigator.pop(context);
                    await _submitPlanRequest(numInstallments, reason);
                  },
                  child: const Text("Submit Request"),
                )
              ],
            );
          }
        );
      }
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
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppTheme.voidBlack, AppTheme.voidBlack.withOpacity(0)],
          stops: const [0.8, 1.0],
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          context.push('/payment-method', extra: widget.invoice);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pay Now"),
            Row(
              children: [
                Text("₦${widget.invoice.totalAmount.toStringAsFixed(2)}"),
                SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
