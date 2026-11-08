import '../../../../core/result/result.dart';
import '../../../home/domain/entities/collar_entity.dart';
import '../../../home/domain/entities/product_entity.dart';

abstract interface class ProductDetailRepository {
  Future<Result<ProductEntity>> getProductById(int id);
  Future<Result<CollarEntity>> getCollarById(int id);
}
