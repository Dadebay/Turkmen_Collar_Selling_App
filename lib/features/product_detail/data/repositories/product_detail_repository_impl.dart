import '../../../../core/result/result.dart';
import '../../../home/domain/entities/collar_entity.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../datasources/product_detail_remote_data_source.dart';

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  const ProductDetailRepositoryImpl(this._remote);
  final ProductDetailRemoteDataSource _remote;

  @override
  Future<Result<ProductEntity>> getProductById(int id) async {
    final result = await _remote.getProductById(id);
    return switch (result) {
      Success(:final data) => Success(data.toEntity()),
      Failure(:final failure) => Failure(failure),
    };
  }

  @override
  Future<Result<CollarEntity>> getCollarById(int id) async {
    final result = await _remote.getCollarById(id);
    return switch (result) {
      Success(:final data) => Success(data.toEntity()),
      Failure(:final failure) => Failure(failure),
    };
  }
}
