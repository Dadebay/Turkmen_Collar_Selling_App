import '../../../../core/result/result.dart';
import '../entities/banner_entity.dart';
import '../entities/category_entity.dart';
import '../entities/collar_entity.dart';
import '../entities/photo_entity.dart';
import '../entities/product_entity.dart';
import '../entities/video_entity.dart';

abstract interface class HomeRepository {
  Future<Result<List<BannerEntity>>> getBanners();
  Future<Result<List<CategoryEntity>>> getCategories();
  Future<Result<List<ProductEntity>>> getMachines();
  Future<Result<List<ProductEntity>>> getClothes();
  Future<Result<List<CollarEntity>>> getCollars();
  Future<Result<List<ProductEntity>>> getGoods();
  Future<Result<List<ProductEntity>>> getCategoryProducts({
    required int categoryId,
    required Map<String, String> params,
  });
  Future<Result<List<ProductEntity>>> searchCollars({required String query});
  Future<Result<List<VideoEntity>>> getVideos();
  Future<Result<List<PhotoEntity>>> getPhotos();
  Future<Result<double>> getUserBalance({bool forceRefresh = true});

  /// Last known balance from a previous `users/me` fetch (no network), or null
  /// if none cached yet. Lets the wallet render instantly on a cold start.
  double? get cachedBalance;
}
