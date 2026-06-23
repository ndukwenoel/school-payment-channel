import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/auth_bloc.dart';
import '../../../core/api_client.dart';
import 'package:dio/dio.dart';

class SchoolStorePage extends StatefulWidget {
  const SchoolStorePage({super.key});

  @override
  State<SchoolStorePage> createState() => _SchoolStorePageState();
}

class _SchoolStorePageState extends State<SchoolStorePage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _storeItems = [];
  List<dynamic> _students = [];
  Map<int, int> _cart = {}; // item_id -> quantity
  int? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final itemsResponse = await _apiClient.dio.get('/api/v1/parents/store/items');
      final studentsResponse = await _apiClient.dio.get('/api/v1/parents/my-students');
      
      if (mounted) {
        setState(() {
          _storeItems = itemsResponse.data;
          _students = studentsResponse.data;
          if (_students.isNotEmpty) {
            _selectedStudentId = _students.first['id'];
          }
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load store items: ${e.response?.data['detail'] ?? e.message}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCart(int itemId, int delta, int maxStock) {
    setState(() {
      final currentQty = _cart[itemId] ?? 0;
      final newQty = currentQty + delta;
      
      if (newQty <= 0) {
        _cart.remove(itemId);
      } else if (newQty <= maxStock) {
        _cart[itemId] = newQty;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum stock reached for this item.')));
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (final item in _storeItems) {
      final qty = _cart[item['id']] ?? 0;
      total += (item['unit_price'] ?? 0.0) * qty;
    }
    return total;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }
    
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final itemsList = _cart.entries.map((e) => {'item_id': e.key, 'quantity': e.value}).toList();
      
      final response = await _apiClient.dio.post('/api/v1/parents/store/purchase', data: {
        'student_id': _selectedStudentId,
        'items': itemsList
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful! Invoice created.')));
        _cart.clear();
        _fetchData(); // refresh stock
        context.go('/invoices'); // Redirect to invoices list to see the new invoice
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: ${e.response?.data['detail'] ?? e.message}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.peachBackground,
      appBar: AppBar(
        title: const Text('School Store', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Items
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AVAILABLE ITEMS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_storeItems.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No items available in the store.', style: TextStyle(color: AppTheme.textMuted)),
                    ))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _storeItems.length,
                        itemBuilder: (context, index) {
                          final item = _storeItems[index];
                          final int itemId = item['id'];
                          final int stock = item['quantity'] ?? 0;
                          final double price = item['unit_price'] ?? 0.0;
                          final int qtyInCart = _cart[itemId] ?? 0;
                          
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag, size: 48, color: AppTheme.sageGreen),
                                  const SizedBox(height: 8),
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(item['category'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text('₦${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 18)),
                                  const Spacer(),
                                  if (stock <= 0)
                                    const Text('Out of Stock', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                                  else
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textMuted),
                                          onPressed: qtyInCart > 0 ? () => _updateCart(itemId, -1, stock) : null,
                                        ),
                                        Text('$qtyInCart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.sageGreen),
                                          onPressed: qtyInCart < stock ? () => _updateCart(itemId, 1, stock) : null,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Cart Panel
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(left: BorderSide(color: AppTheme.sageGreen.withOpacity(0.2))),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("YOUR CART", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                if (_students.isEmpty)
                  const Text("You must link a student to make purchases.", style: TextStyle(color: Colors.redAccent))
                else ...[
                  const Text("Select Student:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedStudentId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _students.map((s) => DropdownMenuItem<int>(
                      value: s['id'],
                      child: Text(s['full_name']),
                    )).toList(),
                    onChanged: (val) {
                      setState(() => _selectedStudentId = val);
                    },
                  ),
                ],
                
                const SizedBox(height: 32),
                
                if (_cart.isEmpty)
                  const Expanded(child: Center(child: Text("Your cart is empty", style: TextStyle(color: AppTheme.textMuted))))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _storeItems.length,
                      itemBuilder: (context, index) {
                        final item = _storeItems[index];
                        final qty = _cart[item['id']] ?? 0;
                        if (qty == 0) return const SizedBox.shrink();
                        
                        final price = item['unit_price'] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item['name']} (x$qty)')),
                              Text('₦${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('₦${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.textDark)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty || _selectedStudentId == null ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sageGreen,
                      foregroundColor: AppTheme.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Checkout to Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Checking out will generate an invoice which you can pay immediately or later from your dashboard.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10), textAlign: TextAlign.center),
              ],
            ),
          )
        ],
      ),
    );
  }
}
