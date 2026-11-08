import 'dart:convert';

import '../../../../core/storage/local_storage.dart';

class FavoritesLocalDataSource {
  const FavoritesLocalDataSource(this._storage);
  final LocalStorage _storage;

  List<int> getFavProductIds() => _decode(_storage.favProductIds);
  List<int> getFavCollarIds() => _decode(_storage.favCollarIds);

  Future<void> saveFavProductIds(List<int> ids) =>
      _storage.saveFavProductIds(jsonEncode(ids));

  Future<void> saveFavCollarIds(List<int> ids) =>
      _storage.saveFavCollarIds(jsonEncode(ids));

  List<int> _decode(String? json) {
    if (json == null) {
      return [];
    }
    try {
      // Older GetStorage migrations saved a JSON string inside another JSON
      // string. Accept both encodings so existing favorites stay visible.
      final decoded = jsonDecode(json);
      final list = decoded is String
          ? jsonDecode(decoded) as List<dynamic>
          : decoded as List<dynamic>;
      // Support both plain id lists and {id, name} maps from old storage
      return list
          .map<int>((e) {
            if (e is int) {
              return e;
            }
            if (e is Map) {
              return int.tryParse(e['id']?.toString() ?? '') ?? 0;
            }
            return int.tryParse(e.toString()) ?? 0;
          })
          .where((id) => id > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
