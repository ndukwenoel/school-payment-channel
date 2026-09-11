class Classroom {
  final int? id;
  final String name;

  Classroom({this.id, required this.name});

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
    id: json['id'],
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class Subject {
  final int? id;
  final String name;

  Subject({this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class CourseTest {
  final int? id;
  final String title;

  CourseTest({this.id, required this.title});

  factory CourseTest.fromJson(Map<String, dynamic> json) => CourseTest(
    id: json['id'],
    title: json['title'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
  };
}

class TestResult {
  final int? id;
  final double score;

  TestResult({this.id, required this.score});

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
    id: json['id'],
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'score': score,
  };
}

class StaffProfile {
  final int? id;
  final String name;

  StaffProfile({this.id, required this.name});

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
    id: json['id'],
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class PayrollRecord {
  final int? id;
  final double amount;

  PayrollRecord({this.id, required this.amount});

  factory PayrollRecord.fromJson(Map<String, dynamic> json) => PayrollRecord(
    id: json['id'],
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
  };
}

class InventoryItem {
  final int? id;
  final String name;
  final int quantity;

  InventoryItem({this.id, required this.name, required this.quantity});

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'],
    name: json['name'] ?? '',
    quantity: json['quantity'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
  };
}

class Broadcast {
  final int? id;
  final String message;

  Broadcast({this.id, required this.message});

  factory Broadcast.fromJson(Map<String, dynamic> json) => Broadcast(
    id: json['id'],
    message: json['message'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
  };
}

class AcademicResource {
  final int? id;
  final String title;

  AcademicResource({this.id, required this.title});

  factory AcademicResource.fromJson(Map<String, dynamic> json) => AcademicResource(
    id: json['id'],
    title: json['title'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
  };
}

class Student {
  final int? id;
  final String name;

  Student({this.id, required this.name});

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
