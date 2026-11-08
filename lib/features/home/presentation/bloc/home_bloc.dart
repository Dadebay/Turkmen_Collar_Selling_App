import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/collar_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
  }

  final HomeRepository _repository;
  int _requestVersion = 0;

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    final requestVersion = ++_requestVersion;
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        _repository.getBanners(),
        _repository.getCategories(),
        _repository.getMachines(),
        _repository.getClothes(),
        _repository.getCollars(),
        _repository.getGoods(),
      ]);
      if (emit.isDone || requestVersion != _requestVersion) {
        return;
      }

      if (results.every((result) => result is Failure)) {
        emit(const HomeError('noConnection2'));
        return;
      }

      final banners = results[0] is Success
          ? (results[0] as Success<List<BannerEntity>>).data
          : <BannerEntity>[];
      final categories = results[1] is Success
          ? (results[1] as Success<List<CategoryEntity>>).data
          : <CategoryEntity>[];
      final machines = results[2] is Success
          ? (results[2] as Success<List<ProductEntity>>).data
          : <ProductEntity>[];
      final clothes = results[3] is Success
          ? (results[3] as Success<List<ProductEntity>>).data
          : <ProductEntity>[];
      final collars = results[4] is Success
          ? (results[4] as Success<List<CollarEntity>>).data
          : <CollarEntity>[];
      final goods = results[5] is Success
          ? (results[5] as Success<List<ProductEntity>>).data
          : <ProductEntity>[];

      emit(
        HomeLoaded(
          banners: banners,
          categories: categories,
          machines: machines,
          clothes: clothes,
          collars: collars,
          goods: goods,
        ),
      );
    } catch (_) {
      if (!emit.isDone && requestVersion == _requestVersion) {
        emit(const HomeError('noConnection2'));
      }
    }
  }
}
