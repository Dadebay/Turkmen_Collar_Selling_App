import '../../../../core/result/result.dart';
import '../../../home/domain/entities/product_entity.dart';

abstract interface class FavoritesRepository {
  List<int> getFavProductIds();
  List<int> getFavCollarIds();
  Future<Result<List<ProductEntity>>> fetchFavProducts();
  Future<Result<List<ProductEntity>>> fetchFavCollars();
  Future<Result<void>> addFavorite({required int id, required bool isCollar});
  Future<Result<void>> removeFavorite({
    required int id,
    required bool isCollar,
  });
}
