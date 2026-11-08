import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/features/home/domain/entities/banner_entity.dart';
import 'package:yaka2/features/home/domain/entities/category_entity.dart';
import 'package:yaka2/features/home/domain/entities/collar_entity.dart';
import 'package:yaka2/features/home/domain/entities/product_entity.dart';
import 'package:yaka2/features/home/domain/repositories/home_repository.dart';
import 'package:yaka2/features/home/presentation/bloc/home_bloc.dart';

void main() {
  test('an older home response cannot replace a newer refresh', () async {
    final repository = _HomeRepository();
    final bloc = HomeBloc(repository);
    final refreshed = bloc.stream.where((state) => state is HomeLoaded).first;

    bloc.add(const HomeLoadRequested());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const HomeRefreshRequested());
    await Future<void>.delayed(Duration.zero);
    expect(repository.bannerRequests, 2);

    repository.second.complete(const Success([BannerEntity(id: 2)]));
    final state = (await refreshed) as HomeLoaded;
    repository.first.complete(const Success([BannerEntity(id: 1)]));
    await Future<void>.delayed(Duration.zero);

    expect(state.banners.single.id, 2);
    expect((bloc.state as HomeLoaded).banners.single.id, 2);
    await bloc.close();
  });
}

class _HomeRepository implements HomeRepository {
  final first = Completer<Result<List<BannerEntity>>>();
  final second = Completer<Result<List<BannerEntity>>>();
  int bannerRequests = 0;

  @override
  Future<Result<List<BannerEntity>>> getBanners() =>
      bannerRequests++ == 0 ? first.future : second.future;

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async =>
      const Success([]);

  @override
  Future<Result<List<ProductEntity>>> getMachines() async => const Success([]);

  @override
  Future<Result<List<ProductEntity>>> getClothes() async => const Success([]);

  @override
  Future<Result<List<CollarEntity>>> getCollars() async => const Success([]);

  @override
  Future<Result<List<ProductEntity>>> getGoods() async => const Success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
