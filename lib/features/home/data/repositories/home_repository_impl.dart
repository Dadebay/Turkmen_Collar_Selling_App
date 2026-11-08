import '../../../../core/result/result.dart';
import '../../../../core/services/account_remote_data_source.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/collar_entity.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({
    required HomeRemoteDataSource remote,
    required AccountRemoteDataSource account,
    required LocalStorage local,
  }) : _remote = remote,
       _account = account,
       _local = local;

  final HomeRemoteDataSource _remote;
  final AccountRemoteDataSource _account;
  final LocalStorage _local;

  @override
  Future<Result<List<BannerEntity>>> getBanners() async {
    final result = await _remote.getBanners();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    final result = await _remote.getCategories();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<ProductEntity>>> getMachines() async {
    final result = await _remote.getMachines();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<ProductEntity>>> getClothes() async {
    final result = await _remote.getClothes();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<CollarEntity>>> getCollars() async {
    final result = await _remote.getCollars();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<ProductEntity>>> getGoods() async {
    final result = await _remote.getGoods();
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<ProductEntity>>> getCategoryProducts({
    required int categoryId,
    required Map<String, String> params,
  }) async {
    final result = await _remote.getCategoryProducts(
      categoryId: categoryId,
      params: params,
    );
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<ProductEntity>>> searchCollars({
    required String query,
  }) async {
    final result = await _remote.searchCollars(query: query);
    return result.when(
      success: (list) => Success(list.map((m) => m.toEntity()).toList()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<VideoEntity>>> getVideos() async {
    final result = await _remote.getVideos();
    return result.when(
      success: (list) => Success(list.cast<VideoEntity>()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<List<PhotoEntity>>> getPhotos() async {
    final result = await _remote.getPhotos();
    return result.when(
      success: (list) => Success(list.cast<PhotoEntity>()),
      failure: Failure.new,
    );
  }

  @override
  Future<Result<double>> getUserBalance({bool forceRefresh = true}) async {
    final result = await _account.getCurrentUser(forceRefresh: forceRefresh);
    return result.when(
      success: (user) => Success(user.balanceAmount),
      failure: Failure.new,
    );
  }

  @override
  double? get cachedBalance {
    final raw = _local.balanceRaw;
    return raw == null ? null : raw / 100;
  }
}
