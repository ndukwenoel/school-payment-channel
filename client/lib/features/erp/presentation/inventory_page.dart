import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<ErpRepository>().getInventory();
      if (mounted) {
        setState(() => _items = items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading inventory: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Inventory Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
                  const SizedBox(height: 16),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (e.g. Uniforms, Books)')),
                  const SizedBox(height: 16),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (nameController.text.isEmpty || categoryController.text.isEmpty) return;
                    setDialogState(() => saving = true);
                    try {
                      await context.read<ErpRepository>().createInventoryItem({
                        'name': nameController.text,
                        'category': categoryController.text,
                        'unit_price': double.tryParse(priceController.text),
                        'quantity': 0,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        _loadInventory();
                      }
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding item: $e")));
                    }
                  },
                  child: saving ? const CircularProgressIndicator() : const Text('Add'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showAdjustStockDialog(Map<String, dynamic> item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Adjust Stock - ${item['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Stock: ${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Enter quantity to add or remove (e.g., 50 or -10):", style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity Change'),
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    final change = int.tryParse(quantityController.text);
                    if (change == null || change == 0) return;
                    setDialogState(() => saving = true);
                    try {
                      await context.read<ErpRepository>().updateStock(item['id'], change);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadInventory();
                      }
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating stock: $e")));
                    }
                  },
                  child: saving ? const CircularProgressIndicator() : const Text('Update'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        title: const Text("INVENTORY"),
        backgroundColor: AppTheme.surfaceDark,
        foregroundColor: Colors.white,
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text("No items in inventory", style: TextStyle(color: AppTheme.textMuted50)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final price = item['unit_price'] != null ? "₦${item['unit_price']}" : "N/A";
                    return Card(
                      color: AppTheme.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.limeLight.withOpacity(0.2),
                          child: const Icon(Icons.inventory_2, color: AppTheme.limeLight),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item['category']} • Price: $price"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Stock: ${item['quantity']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: (item['quantity'] as int) < 10 ? Colors.redAccent : Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showAdjustStockDialog(item),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: AppTheme.bluePale,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Adjust'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppTheme.limeLight,
        child: const Icon(Icons.add, color: AppTheme.voidBlack),
      ),
    );
  }
}
