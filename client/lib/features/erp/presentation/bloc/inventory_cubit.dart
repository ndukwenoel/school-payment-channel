import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/models/erp_models.dart';

abstract class InventoryState {}

class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;

  InventoryLoaded({this.items = const []});
}
class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository repository;

  InventoryCubit(this.repository) : super(InventoryInitial());

  Future<void> loadInventory() async {
    emit(InventoryLoading());
    try {
      final items = await repository.getInventory();
      emit(InventoryLoaded(items: items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
