import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/features/favorites/data/datasources/favorites_local_data_source.dart';

void main() {
  test('reads favorites from both old and current storage formats', () {
    final storage = _FavoritesStorage(
      productIds: jsonEncode(
        jsonEncode([
          1,
          {'id': '2'},
        ]),
      ),
      collarIds: jsonEncode([
        3,
        {'id': 4},
      ]),
    );
    final source = FavoritesLocalDataSource(storage);

    expect(source.getFavProductIds(), [1, 2]);
    expect(source.getFavCollarIds(), [3, 4]);
  });
}

class _FavoritesStorage extends LocalStorage {
  _FavoritesStorage({required this.productIds, required this.collarIds});

  final String productIds;
  final String collarIds;

  @override
  String? get favProductIds => productIds;

  @override
  String? get favCollarIds => collarIds;
}
