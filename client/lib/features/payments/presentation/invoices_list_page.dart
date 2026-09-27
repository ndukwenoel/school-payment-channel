import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_models.dart' as auth;
import '../../../core/theme.dart';

class InvoicesListPage extends StatefulWidget {
  const InvoicesListPage({super.key});

  @override
  State<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends State<InvoicesListPage> {
  bool _loading = true;
  Map<int, List<Invoice>> _invoices = {};
  List<Invoice> _adminInvoices = [];
  auth.User? _currentUser;

  // Filter & Search states for Admin
  String _selectedStatus = 'All';
  String _selectedClass = 'All Classes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = ['All', 'Pending', 'Partial', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final authRepo = context.read<AuthRepository>();
      final repo = context.read<PaymentRepository>();
      final user = await authRepo.getCurrentUser();
      final bool isAdmin = user.role != 'parent';

      if (isAdmin) {
        final invoices = await repo.getInvoices();
        if (mounted) {
          setState(() {
            _currentUser = user;
            _adminInvoices = invoices;
            _loading = false;
          });
        }
      } else {
        final students = await repo.getMyStudents();
        Map<int, List<Invoice>> invoicesMap = {};
        for (var s in students) {
          final invoices = await repo.getStudentInvoices(s.id);
          invoicesMap[s.id] = invoices;
        }

        if (mounted) {
          setState(() {
            _invoices = invoicesMap;
            _currentUser = user;
            _loading = false;
          });
        }
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

  List<String> get _availableClasses {
    final Set<String> classes = {};
    for (var inv in _adminInvoices) {
      final cls = inv.studentGrade ?? inv.classroomName;
      if (cls != null && cls.trim().isNotEmpty) {
        classes.add(cls.trim());
      }
    }
    final sorted = classes.toList()..sort();
    return ['All Classes', ...sorted];
  }

  List<Invoice> get _filteredAdminInvoices {
    return _adminInvoices.where((inv) {
      if (_selectedStatus != 'All' && inv.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedClass != 'All Classes') {
        final cls = inv.studentGrade ?? inv.classroomName;
        if (cls == null || cls.toLowerCase() != _selectedClass.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = inv.title.toLowerCase().contains(q);
        final matchStudent = inv.studentName?.toLowerCase().contains(q) ?? false;
        final matchEnrollment = inv.enrollmentNumber?.toLowerCase().contains(q) ?? false;
        final matchClass = (inv.studentGrade?.toLowerCase().contains(q) ?? false) ||
                           (inv.classroomName?.toLowerCase().contains(q) ?? false);
        if (!matchTitle && !matchStudent && !matchEnrollment && !matchClass) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdmin = _currentUser != null && _currentUser!.role != 'parent';

    if (isAdmin) {
      return _buildAdminInvoiceView();
    } else {
      return _buildParentInvoiceView();
    }
  }

  // =========================================================================
  // ADMIN INVOICE CONSOLE
  // =========================================================================

  Widget _buildAdminInvoiceView() {
    final filtered = _filteredAdminInvoices;
    final bool hasActiveFilters = _selectedStatus != 'All' || _selectedClass != 'All Classes' || _searchQuery.isNotEmpty;

    // Metrics computed from filtered set
    final int totalCount = _adminInvoices.length;
    double totalValue = 0;
    double totalCollected = 0;
    double totalOutstanding = 0;
    int overdueCount = 0;

    for (var inv in filtered) {
      totalValue += inv.totalAmount;
      if (inv.status == 'paid') {
        totalCollected += inv.totalAmount;
      } else {
        totalOutstanding += inv.totalAmount;
        if (inv.status == 'overdue') overdueCount++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "INVOICES MANAGEMENT",
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasActiveFilters
                          ? "Showing ${filtered.length} of $totalCount invoices matching filters"
                          : "Track, filter, and review all student billing records ($totalCount total)",
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                      tooltip: "Refresh Invoices",
                      onPressed: _loadData,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Create Fees"),
                      onPressed: () => context.push('/erp/fees'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Stat Cards
            Row(
              children: [
                _buildKpiCard("TOTAL INVOICES", "$totalCount", "₦${totalValue.toStringAsFixed(2)}", AppTheme.primaryBlue, Icons.receipt_long),
                const SizedBox(width: 14),
                _buildKpiCard("COLLECTED", "₦${totalCollected.toStringAsFixed(2)}", "Paid in full", AppTheme.success, Icons.check_circle_outline),
                const SizedBox(width: 14),
                _buildKpiCard("OUTSTANDING", "₦${totalOutstanding.toStringAsFixed(2)}", "Unpaid balance", AppTheme.warning, Icons.pending_actions),
                const SizedBox(width: 14),
                _buildKpiCard("OVERDUE", "$overdueCount invoices", "Action required", AppTheme.error, Icons.warning_amber_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // Filter & Search Controls
            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: "Search by student name, enrollment no, title, or class...",
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Class / Grade Dropdown Filter
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedClass != 'All Classes' ? AppTheme.primaryBlue : Colors.black.withOpacity(0.06),
                      width: _selectedClass != 'All Classes' ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _availableClasses.contains(_selectedClass) ? _selectedClass : 'All Classes',
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textMuted),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      items: _availableClasses.map((cls) {
                        return DropdownMenuItem<String>(
                          value: cls,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cls == 'All Classes' ? Icons.apps : Icons.school_outlined,
                                size: 16,
                                color: _selectedClass == cls ? AppTheme.primaryBlue : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(cls),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedClass = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Status Filter Chips
                Wrap(
                  spacing: 8,
                  children: _statusFilters.map((st) {
                    final bool isSelected = _selectedStatus == st;
                    return ChoiceChip(
                      label: Text(st, style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      )),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      backgroundColor: AppTheme.cardBackground,
                      onSelected: (val) {
                        if (val) setState(() => _selectedStatus = st);
                      },
                    );
                  }).toList(),
                ),

                if (_selectedStatus != 'All' || _selectedClass != 'All Classes' || _searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off_outlined, color: AppTheme.error, size: 20),
                    tooltip: "Reset All Filters",
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'All';
                        _selectedClass = 'All Classes';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Invoices List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            "No invoices match your filter criteria.",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final inv = filtered[index];
                        return _buildAdminInvoiceTile(inv);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String mainVal, String subVal, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(mainVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subVal, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminInvoiceTile(Invoice inv) {
    final statusColor = _getStatusColor(inv.status);
    final String studentLabel = inv.studentName != null && inv.studentName!.isNotEmpty
        ? "${inv.studentName} (${inv.enrollmentNumber ?? 'No Reg'})"
        : "Student #${inv.studentId}";

    final dueDateStr = "${inv.dueDate.year}-${inv.dueDate.month.toString().padLeft(2, '0')}-${inv.dueDate.day.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Status Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getStatusIcon(inv.status), color: statusColor, size: 22),
          ),
          const SizedBox(width: 18),

          // Invoice & Student Info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studentLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("INV-${inv.id}", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    ),
                    if (inv.studentGrade != null || inv.classroomName != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          inv.studentGrade ?? inv.classroomName!,
                          style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${inv.title} • ${inv.studentGrade ?? inv.classroomName ?? 'Class N/A'} • ${inv.lineItems.length} item${inv.lineItems.length == 1 ? '' : 's'}",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // Due Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DUE DATE", style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(dueDateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              inv.status.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 24),

          // Amount
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₦${inv.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // View Details Action
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryBlue),
            tooltip: "View Invoice Details",
            onPressed: () => context.push('/invoice-detail', extra: inv),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return AppTheme.success;
      case 'pending': return AppTheme.warning;
      case 'partial': return Colors.purple;
      case 'overdue': return AppTheme.error;
      default: return AppTheme.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Icons.check_circle;
      case 'pending': return Icons.hourglass_top_rounded;
      case 'partial': return Icons.pie_chart_outline;
      case 'overdue': return Icons.warning_rounded;
      default: return Icons.receipt_outlined;
    }
  }

  // =========================================================================
  // PARENT INVOICE VIEW
  // =========================================================================

  Widget _buildParentInvoiceView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                    if (_currentUser != null) _buildCreditBalanceCard(),
                    if (_currentUser != null) const SizedBox(height: 24),
                  ],
                ),
              ),
              const TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primaryBlue,
                tabs: [
                  Tab(text: "Pending"),
                  Tab(text: "Partial"),
                  Tab(text: "Paid"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTabContent('pending'),
                    _buildTabContent('partial'),
                    _buildTabContent('paid'),
                  ],
                ),
              ),
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
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 0.5, fontWeight: FontWeight.bold),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppTheme.primaryBlue, size: 18),
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
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL OUTSTANDING",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "₦${_totalOutstanding.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          const SizedBox(height: 4),
          const Text(
            "Due by Next Month",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/store'),
            child: _buildActionCard(
              title: "School Store",
              color: AppTheme.cardBackground,
              textColor: AppTheme.textDark,
              icon: Icons.storefront,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionCard(
            title: "Download Receipts",
            color: AppTheme.cardBackground,
            textColor: AppTheme.textDark,
            icon: Icons.download,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/history'),
            child: _buildActionCard(
              title: "Payment History",
              color: AppTheme.cardBackground,
              textColor: AppTheme.textDark,
              icon: Icons.history,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required Color color, required Color textColor, required IconData icon}) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          Text(title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreditBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppTheme.primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text("CREDIT BALANCE", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: _showTopUpDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text("TOP UP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₦${_currentUser!.creditBalance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Auto-Pay Future Invoices", style: TextStyle(fontSize: 13, color: AppTheme.textDark)),
              Switch(
                value: _currentUser!.autoPayEnabled,
                onChanged: (val) => _toggleAutoPay(),
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoPay() async {
    try {
      final repo = context.read<PaymentRepository>();
      final result = await repo.toggleAutoPay();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Top Up Balance", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter amount to add to your credit balance. In production, this initiates Paystack/Flutterwave.",
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount (₦)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text);
              if (amt != null && amt > 0) {
                Navigator.pop(ctx);
                try {
                  setState(() => _loading = true);
                  final repo = context.read<PaymentRepository>();
                  await repo.topUpWallet(amt, "TOPUP-${DateTime.now().millisecondsSinceEpoch}");
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Top-up successful!")));
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              }
            },
            child: const Text("Top Up"),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String filterStatus) {
    List<Widget> items = [];
    for (var list in _invoices.values) {
      for (var invoice in list) {
        if (filterStatus == 'pending' && invoice.status != 'pending') continue;
        if (filterStatus == 'partial' && invoice.status != 'partial') continue;
        if (filterStatus == 'paid' && invoice.status != 'paid') continue;

        items.add(_buildInvoiceItem(invoice));
      }
    }
    if (items.isEmpty) {
      return Center(
        child: Text("No $filterStatus invoices found.", style: const TextStyle(color: AppTheme.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildInvoiceItem(Invoice invoice) {
    bool isDueSoon = invoice.dueDate.difference(DateTime.now()).inDays < 7;
    return GestureDetector(
      onTap: () => context.push('/invoice-detail', extra: invoice),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: isDueSoon ? AppTheme.warning : AppTheme.primaryBlue, width: 4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(
                  isDueSoon ? "Due soon" : "Due ${invoice.dueDate.month}/${invoice.dueDate.day}",
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₦${invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                if (isDueSoon)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: const Text("UNPAID", style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDock() {
    List<int> unpaidInvoiceIds = [];
    for (var list in _invoices.values) {
      for (var f in list) {
        if (f.status != 'paid') {
          unpaidInvoiceIds.add(f.id);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: ElevatedButton(
        onPressed: unpaidInvoiceIds.isNotEmpty ? () => _handlePayTotal(unpaidInvoiceIds) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pay Total (Consolidated)", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text("₦${_totalOutstanding.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayTotal(List<int> invoiceIds) async {
    setState(() => _loading = true);
    try {
      final repo = context.read<PaymentRepository>();
      final bundle = await repo.createPaymentBundle(invoiceIds);

      if (mounted) {
        setState(() => _loading = false);
        _showBundleTransferDialog(bundle['reference'], bundle['total_amount']);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating bundle: $e")));
      }
    }
  }

  void _showBundleTransferDialog(String reference, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Consolidated Payment Bundle", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("To clear all your outstanding invoices with a single payment, please transfer the exact total below:"),
            const SizedBox(height: 16),
            Text("Total Amount: ₦${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.success)),
            const SizedBox(height: 16),
            const Text("Bank: Opay", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Account Name: School Payment Gateway", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Account No: 1234567890", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            const SizedBox(height: 16),
            const Text(
              "IMPORTANT: You must use the exact reference code below as your transfer narration. This ensures automatic splitting and reconciliation.",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Text(reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2, color: AppTheme.textDark)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("I have transferred"),
          ),
        ],
      ),
    );
  }
}
