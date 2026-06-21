import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

/// Displays all course tests for the school, grouped by classroom.
/// Teachers/admins can create a new test via the FAB and tap into
/// any existing test to enter or view student scores.
class CourseTestsPage extends StatefulWidget {
  const CourseTestsPage({super.key});

  @override
  State<CourseTestsPage> createState() => _CourseTestsPageState();
}

class _CourseTestsPageState extends State<CourseTestsPage> {
  List<dynamic> _tests = [];
  List<dynamic> _classrooms = [];
  bool _loading = true;
  int? _selectedClassroomId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<ErpRepository>();
      final results = await Future.wait([
        repo.getClassrooms(),
        repo.getCourseTests(classroomId: _selectedClassroomId),
      ]);
      if (mounted) {
        setState(() {
          _classrooms = results[0];
          _tests = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tests: $e')),
        );
      }
    }
  }

  Future<void> _filterByClassroom(int? classroomId) async {
    setState(() {
      _selectedClassroomId = classroomId;
      _loading = true;
    });
    try {
      final tests = await context.read<ErpRepository>().getCourseTests(
            classroomId: classroomId,
          );
      if (mounted) setState(() { _tests = tests; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateTestDialog() {
    final titleCtrl = TextEditingController();
    String testType = 'test';
    double maxScore = 100;
    String term = 'First Term';
    String year = '2025/2026';
    int? subjectId;
    int? classroomId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.voidBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, scrollCtrl) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: ListView(
              controller: scrollCtrl,
              children: [
                const Text('NEW COURSE TEST',
                    style: TextStyle(
                        color: AppTheme.limeLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Test Title (e.g. Mid-Term Exam)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: testType,
                  decoration: const InputDecoration(
                    labelText: 'Test Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['test', 'exam', 'ca', 'quiz', 'assignment']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setModal(() => testType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: classroomId,
                  decoration: const InputDecoration(
                    labelText: 'Classroom',
                    border: OutlineInputBorder(),
                  ),
                  items: _classrooms
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          ))
                      .toList(),
                  onChanged: (v) => setModal(() => classroomId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Score',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => maxScore = double.tryParse(v) ?? 100,
                  controller: TextEditingController(text: '100'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: term,
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(),
                  ),
                  items: ['First Term', 'Second Term', 'Third Term']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModal(() => term = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Academic Year (e.g. 2025/2026)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => year = v,
                  controller: TextEditingController(text: year),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeLight,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty || classroomId == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Title and classroom are required')),
                        );
                        return;
                      }
                      try {
                        await context.read<ErpRepository>().createCourseTest({
                          'title': titleCtrl.text,
                          'test_type': testType,
                          'max_score': maxScore,
                          'term': term,
                          'academic_year': year,
                          'classroom_id': classroomId,
                          'subject_id': subjectId ?? 1, // fallback; real app would require selection
                          'school_id': 1, // populated server-side from token but schema requires it
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('CREATE TEST',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.voidBlack,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COURSE TESTS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text('Manage tests & record scores',
                style: TextStyle(color: AppTheme.textMuted50, fontSize: 11)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTestDialog,
        backgroundColor: AppTheme.limeLight,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NEW TEST', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildClassroomFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _tests.length,
                          itemBuilder: (context, index) {
                            return _buildTestCard(_tests[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomFilter() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip('All Classes', null),
          ..._classrooms.map((c) => _filterChip(c['name'], c['id'] as int)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? id) {
    final isSelected = _selectedClassroomId == id;
    return GestureDetector(
      onTap: () => _filterByClassroom(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.limeLight : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final typeColors = {
      'exam': Colors.redAccent,
      'test': AppTheme.blueVibrant,
      'ca': AppTheme.limeLight,
      'quiz': Colors.purpleAccent,
      'assignment': Colors.orangeAccent,
    };
    final color = typeColors[test['test_type']] ?? AppTheme.blueVibrant;

    return GestureDetector(
      onTap: () => context.push('/erp/tests/entry', extra: test),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(_testTypeIcon(test['test_type']), color: color, size: 22),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _tag(test['test_type'].toString().toUpperCase(), color),
                      const SizedBox(width: 8),
                      _tag(test['term'], AppTheme.textMuted50),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Max: ${test['max_score'].toStringAsFixed(0)} pts  •  ${test['academic_year']}',
                      style: const TextStyle(color: AppTheme.textMuted50, fontSize: 11)),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.edit_note, color: AppTheme.limeLight, size: 20),
                const SizedBox(height: 4),
                Text('Enter\nScores',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.limeLight, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  IconData _testTypeIcon(String type) {
    switch (type) {
      case 'exam': return Icons.school;
      case 'ca': return Icons.assignment_turned_in;
      case 'quiz': return Icons.quiz;
      case 'assignment': return Icons.description;
      default: return Icons.edit;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppTheme.textMuted50),
          const SizedBox(height: 16),
          const Text('No tests found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          const Text('Tap + NEW TEST to create your first course test.',
              style: TextStyle(color: AppTheme.textMuted50, fontSize: 13)),
        ],
      ),
    );
  }
}
