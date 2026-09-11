import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  
  final _publicKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/settings/');
      if (mounted) {
        _publicKeyController.text = res.data['paystack_public_key'] ?? '';
        _secretKeyController.text = res.data['paystack_secret_key'] ?? '';
        _feeController.text = res.data['platform_fee_percentage']?.toString() ?? '1.5';
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final data = {
        'paystack_public_key': _publicKeyController.text,
        'paystack_secret_key': _secretKeyController.text,
        'platform_fee_percentage': double.tryParse(_feeController.text) ?? 1.5,
      };
      
      await _apiClient.dio.patch('/settings/', data: data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global settings saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("GLOBAL PLATFORM SETTINGS", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Gateway (Paystack)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _publicKeyController,
                    decoration: const InputDecoration(labelText: "Public Key", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _secretKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Secret Key", border: OutlineInputBorder()),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text("Platform Rules", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _feeController,
                    decoration: const InputDecoration(labelText: "Platform Transaction Fee (%)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _saveSettings,
                      child: const Text("Save Configuration", style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
