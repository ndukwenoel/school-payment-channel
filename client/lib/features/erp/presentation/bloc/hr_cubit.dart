import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/hr_repository.dart';
import '../../data/models/erp_models.dart';

abstract class HrState {}

class HrInitial extends HrState {}
class HrLoading extends HrState {}
class HrLoaded extends HrState {
  final List<StaffProfile> staff;
  final List<PayrollRecord> payrollHistory;

  HrLoaded({
    this.staff = const [],
    this.payrollHistory = const [],
  });
}
class HrError extends HrState {
  final String message;
  HrError(this.message);
}

class HrCubit extends Cubit<HrState> {
  final HrRepository repository;

  HrCubit(this.repository) : super(HrInitial());

  Future<void> loadStaff() async {
    emit(HrLoading());
    try {
      final staff = await repository.getStaff();
      emit(HrLoaded(staff: staff));
    } catch (e) {
      emit(HrError(e.toString()));
    }
  }

  Future<void> loadPayrollHistory(String month, int year) async {
    emit(HrLoading());
    try {
      final history = await repository.getPayrollHistory(month, year);
      emit(HrLoaded(payrollHistory: history));
    } catch (e) {
      emit(HrError(e.toString()));
    }
  }
}
