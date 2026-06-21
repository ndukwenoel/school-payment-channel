import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

/// Displays all students in a classroom for a specific [CourseTest]
/// and allows inline bulk score entry. Submits all scores in a
/// single API call via the bulk endpoint.
class TestResultsEntryPage extends StatefulWidget {
  final Map<String, dynamic> test;

  const TestResultsEntryPage({super.key, required this.test});

  @override
  State<TestResultsEntryPage> createState() => _TestResultsEntryPageState();
}

class _TestResultsEntryPageState extends State<TestResultsEntryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _existingResults = [];
  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, TextEditingController> _remarkControllers = {};

  bool _loadingStudents = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _scoreControllers.values) c.dispose();
    for (final c in _remarkControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingStudents = true);
    try {
      final repo = context.read<ErpRepository>();
      final testId = widget.test['id'] as int;

      final results = await repo.getTestResults(testId);

      if (mounted) {
        setState(() {
          _existingResults = results;
          _loadingStudents = false;

          // Pre-fill controllers from existing results
          for (final r in results) {
            final studentId = r['student_id'] as int;
            _scoreControllers[studentId] =
                TextEditingController(text: r['score'].toString());
            _remarkControllers[studentId] =
                TextEditingController(text: r['remarks'] ?? '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStudents = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _addStudentRow(int studentId, String studentName) {
    if (_scoreControllers.containsKey(studentId)) return;
    setState(() {
      _scoreControllers[studentId] = TextEditingController();
      _remarkControllers[studentId] = TextEditingController();
    });
  }

  Future<void> _submitScores() async {
    final results = <Map<String, dynamic>>[];
    bool hasError = false;

    _scoreControllers.forEach((studentId, ctrl) {
      final scoreText = ctrl.text.trim();
      if (scoreText.isEmpty) return;
      final score = double.tryParse(scoreText);
      if (score == null) {
        hasError = true;
        return;
      }
      results.add({
        'student_id': studentId,
        'score': score,
        'remarks': _remarkControllers[studentId]?.text.trim(),
      });
    });

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('One or more scores are invalid numbers')),
      );
      return;
    }

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scores entered yet')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final testId = widget.test['id'] as int;
      final res =
          await context.read<ErpRepository>().recordBulkResults(testId, results);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${res['saved_count']} scores saved${res['errors'].isNotEmpty ? ' (${res['errors'].length} errors)' : ''}'),
            backgroundColor: AppTheme.limeLight.withOpacity(0.9),
          ),
        );
        _loadData(); // Refresh results tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submit failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showAddStudentDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Add Student Row',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Student ID', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Name (label only)', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeLight),
            onPressed: () {
              final id = int.tryParse(idCtrl.text.trim());
              if (id != null) {
                _addStudentRow(id, nameCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.test;
    final maxScore = (test['max_score'] as num).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(test['title'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
                '${test['test_type'].toString().toUpperCase()}  •  Max: ${maxScore.toStringAsFixed(0)} pts',
                style:
                    const TextStyle(color: AppTheme.textMuted50, fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.limeLight,
          labelColor: AppTheme.limeLight,
          unselectedLabelColor: AppTheme.textMuted50,
          tabs: const [
            Tab(text: 'ENTER SCORES'),
            Tab(text: 'RESULTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntryTab(maxScore),
          _buildResultsTab(maxScore),
        ],
      ),
    );
  }

  // ─── Entry Tab ────────────────────────────────────────────────────────────

  Widget _buildEntryTab(double maxScore) {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildEntryHeader(maxScore),
        Expanded(
          child: _scoreControllers.isEmpty
              ? _buildEntryEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  children: _scoreControllers.keys
                      .map((studentId) => _buildScoreRow(studentId, maxScore))
                      .toList(),
                ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildEntryHeader(double maxScore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_scoreControllers.length} students  •  Max score: ${maxScore.toStringAsFixed(0)}',
              style:
                  const TextStyle(color: AppTheme.textMuted50, fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: _showAddStudentDialog,
            icon: const Icon(Icons.person_add_alt_1, size: 16,
                color: AppTheme.blueVibrant),
            label: const Text('Add Student',
                style: TextStyle(color: AppTheme.blueVibrant, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(int studentId, double maxScore) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.blueVibrant.withOpacity(0.15),
            child: Text(
              'S$studentId',
              style: const TextStyle(
                  color: AppTheme.blueVibrant,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text('Student #$studentId',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _scoreControllers[studentId],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: AppTheme.textMuted50),
                suffix: Text('/${maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.textMuted50, fontSize: 12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.limeLight),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            tooltip: 'Remove',
            onPressed: () => setState(() {
              _scoreControllers.remove(studentId)?.dispose();
              _remarkControllers.remove(studentId)?.dispose();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add_outlined,
              size: 60, color: AppTheme.textMuted50),
          const SizedBox(height: 16),
          const Text('No students added yet',
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Use "Add Student" above to add score rows.',
              style: TextStyle(color: AppTheme.textMuted50, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submitScores,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.limeLight,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : const Text('SUBMIT ALL SCORES',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }

  // ─── Results Tab ──────────────────────────────────────────────────────────

  Widget _buildResultsTab(double maxScore) {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_existingResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 60, color: AppTheme.textMuted50),
            const SizedBox(height: 16),
            const Text('No results recorded yet',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Go to Score Entry →',
                  style: TextStyle(color: AppTheme.limeLight)),
            ),
          ],
        ),
      );
    }

    final sorted = List.from(_existingResults)
      ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

    final highest = (sorted.first['score'] as num).toDouble();
    final avg =
        sorted.map((r) => (r['score'] as num).toDouble()).reduce((a, b) => a + b) /
            sorted.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildResultsSummary(sorted.length, highest, avg, maxScore),
          const SizedBox(height: 24),
          const Text('LEADERBOARD',
              style: TextStyle(
                  color: AppTheme.textMuted50,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final r = entry.value;
            return _buildResultRow(rank, r, maxScore);
          }),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(int count, double highest, double avg, double max) {
    return Row(
      children: [
        Expanded(
            child: _summaryCard('STUDENTS', '$count',
                Icons.groups_outlined, AppTheme.blueVibrant)),
        const SizedBox(width: 12),
        Expanded(
            child: _summaryCard('HIGHEST', '${highest.toStringAsFixed(1)}/$max',
                Icons.emoji_events_outlined, AppTheme.limeLight)),
        const SizedBox(width: 12),
        Expanded(
            child: _summaryCard('AVERAGE', '${avg.toStringAsFixed(1)}/$max',
                Icons.analytics_outlined, Colors.orangeAccent)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textMuted50, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResultRow(int rank, Map<String, dynamic> result, double maxScore) {
    final score = (result['score'] as num).toDouble();
    final pct = (score / maxScore).clamp(0.0, 1.0);
    final rankColors = [
      const Color(0xFFFFD700), // gold
      const Color(0xFFC0C0C0), // silver
      const Color(0xFFCD7F32), // bronze
    ];
    final rankColor =
        rank <= 3 ? rankColors[rank - 1] : AppTheme.textMuted50;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Student #${result['student_id']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                    color: pct >= 0.7
                        ? AppTheme.limeLight
                        : pct >= 0.5
                            ? Colors.orangeAccent
                            : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.7
                    ? AppTheme.limeLight
                    : pct >= 0.5
                        ? Colors.orangeAccent
                        : Colors.redAccent,
              ),
            ),
          ),
          if (result['remarks'] != null &&
              (result['remarks'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('"${result['remarks']}"',
                  style: const TextStyle(
                      color: AppTheme.textMuted50,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }
}
