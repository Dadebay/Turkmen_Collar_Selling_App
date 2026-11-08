import 'package:bloc/bloc.dart';

import '../../../../core/result/result.dart';
import '../../../home/domain/entities/collar_entity.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/product_detail_repository.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._repository) : super(ProductDetailInitial()) {
    on<ProductDetailLoadRequested>(_onLoad);
  }

  final ProductDetailRepository _repository;

  Future<void> _onLoad(
    ProductDetailLoadRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(ProductDetailLoading());
    if (event.isCollar) {
      final result = await _repository.getCollarById(event.id);
      switch (result) {
        case Success(:final data):
          emit(ProductDetailCollarLoaded(data));
        case Failure(:final failure):
          emit(ProductDetailError(failure.message));
      }
    } else {
      final result = await _repository.getProductById(event.id);
      switch (result) {
        case Success(:final data):
          emit(ProductDetailLoaded(data));
        case Failure(:final failure):
          emit(ProductDetailError(failure.message));
      }
    }
  }
}
