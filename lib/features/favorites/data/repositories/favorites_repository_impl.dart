import '../../../../core/result/result.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl({required this.local, required this.remote});

  final FavoritesLocalDataSource local;
  final FavoritesRemoteDataSource remote;

  @override
  List<int> getFavProductIds() => local.getFavProductIds();

  @override
  List<int> getFavCollarIds() => local.getFavCollarIds();

  @override
  Future<Result<List<ProductEntity>>> fetchFavProducts() async {
    final result = await remote.fetchFavProducts();
    return switch (result) {
      Success(:final data) => Success(data.map((m) => m.toEntity()).toList()),
      Failure(:final failure) => Failure(failure),
    };
  }

  @override
  Future<Result<List<ProductEntity>>> fetchFavCollars() async {
    final result = await remote.fetchFavCollars();
    return switch (result) {
      Success(:final data) => Success(data.map((m) => m.toEntity()).toList()),
      Failure(:final failure) => Failure(failure),
    };
  }

  @override
  Future<Result<void>> addFavorite({
    required int id,
    required bool isCollar,
  }) async {
    final result = await remote.addFavorite(id: id, isCollar: isCollar);
    if (result is Success) {
      if (isCollar) {
        final ids = local.getFavCollarIds();
        if (!ids.contains(id)) {
          await local.saveFavCollarIds([...ids, id]);
        }
      } else {
        final ids = local.getFavProductIds();
        if (!ids.contains(id)) {
          await local.saveFavProductIds([...ids, id]);
        }
      }
    }
    return result;
  }

  @override
  Future<Result<void>> removeFavorite({
    required int id,
    required bool isCollar,
  }) async {
    final result = await remote.removeFavorite(id: id, isCollar: isCollar);
    if (result is Success) {
      if (isCollar) {
        final ids = local.getFavCollarIds();
        await local.saveFavCollarIds(ids.where((e) => e != id).toList());
      } else {
        final ids = local.getFavProductIds();
        await local.saveFavProductIds(ids.where((e) => e != id).toList());
      }
    }
    return result;
  }
}
