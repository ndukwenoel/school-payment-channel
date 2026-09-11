import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../data/models/erp_models.dart';

abstract class CollaborationState {}

class CollaborationInitial extends CollaborationState {}
class CollaborationLoading extends CollaborationState {}
class CollaborationLoaded extends CollaborationState {
  final List<AcademicResource> pendingResources;

  CollaborationLoaded({this.pendingResources = const []});
}
class CollaborationError extends CollaborationState {
  final String message;
  CollaborationError(this.message);
}

class CollaborationCubit extends Cubit<CollaborationState> {
  final CollaborationRepository repository;

  CollaborationCubit(this.repository) : super(CollaborationInitial());

  Future<void> loadPendingResources() async {
    emit(CollaborationLoading());
    try {
      final resources = await repository.getPendingResources();
      emit(CollaborationLoaded(pendingResources: resources));
    } catch (e) {
      emit(CollaborationError(e.toString()));
    }
  }
}
