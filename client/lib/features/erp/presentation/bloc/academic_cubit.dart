import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/academic_repository.dart';
import '../../data/models/erp_models.dart';

abstract class AcademicState {}

class AcademicInitial extends AcademicState {}
class AcademicLoading extends AcademicState {}
class AcademicLoaded extends AcademicState {
  final List<Classroom> classrooms;
  final List<Subject> subjects;
  final List<Student> students;

  AcademicLoaded({
    this.classrooms = const [],
    this.subjects = const [],
    this.students = const [],
  });
}
class AcademicError extends AcademicState {
  final String message;
  AcademicError(this.message);
}

class AcademicCubit extends Cubit<AcademicState> {
  final AcademicRepository repository;

  AcademicCubit(this.repository) : super(AcademicInitial());

  Future<void> loadDashboardData() async {
    emit(AcademicLoading());
    try {
      final classrooms = await repository.getClassrooms();
      final subjects = await repository.getSubjects();
      final students = await repository.getStudents();
      emit(AcademicLoaded(classrooms: classrooms, subjects: subjects, students: students));
    } catch (e) {
      emit(AcademicError(e.toString()));
    }
  }

  // Other specific load functions can be added as needed.
}
