import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedClass = "JSS 1A";

  final List<Map<String, dynamic>> _students = [
    {"id": 1, "name": "John Doe", "status": "present", "remarks": ""},
    {"id": 2, "name": "Jane Smith", "status": "present", "remarks": ""},
    {"id": 3, "name": "Samuel Jackson", "status": "absent", "remarks": "Sick"},
    {"id": 4, "name": "Mary Johnson", "status": "late", "remarks": "Traffic"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Attendance Tracker"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final s = _students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusChip(s, "present", Colors.green),
                            const SizedBox(width: 8),
                            _buildStatusChip(s, "late", Colors.orange),
                            const SizedBox(width: 8),
                            _buildStatusChip(s, "absent", Colors.red),
                          ],
                        ),
                        if (s["status"] != "present") ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: s["remarks"],
                            decoration: const InputDecoration(
                              labelText: "Remarks (Optional)",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() => s["remarks"] = val);
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildSaveDock(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder()),
              items: ["JSS 1A", "JSS 1B", "SS 3 Science"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedClass = val);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
                child: Text("${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> student, String status, Color color) {
    bool isSelected = student["status"] == status;
    return ChoiceChip(
      label: Text(status.toUpperCase()),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => student["status"] = status);
      },
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildSaveDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance saved successfully!")));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
          child: const Text("Save Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
