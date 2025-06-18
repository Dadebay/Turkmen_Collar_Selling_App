import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:yaka2/app/feature/favorites/services/fav_service.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/constants/index.dart';

class FavoritesController extends GetxController {
  final RxBool isLoadingCollars = true.obs;
  final RxBool isLoadingProducts = true.obs;
  final RxString collarError = ''.obs;
  final RxString productError = ''.obs;
  final RxList<ProductModel> favoriteCollars = <ProductModel>[].obs;
  final RxList<ProductModel> favoriteProducts = <ProductModel>[].obs;

  final RxList<Map<String, dynamic>> favProductListIds = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> favCollarListIds = <Map<String, dynamic>>[].obs;
  final storage = GetStorage();

  final String instanceId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void onInit() {
    super.onInit();
    log('FavoritesController ($instanceId) onInit');
    _loadFavIdListsFromStorage();
    fetchFavoriteCollars();
    fetchFavoriteProducts();
  }

  Future<void> fetchFavoriteCollars({bool force = false}) async {
    if (!force && favoriteCollars.isNotEmpty && !isLoadingCollars.value) return;

    log('FavoritesController ($instanceId) fetching favorite COLLARS...');
    try {
      isLoadingCollars.value = true;
      collarError.value = '';
      final collars = await FavService().getCollarFavList();
      favoriteCollars.assignAll(collars);
      favCollarListIds.assignAll(
        collars.map((e) => {'id': e.id, 'name': e.name ?? ''}).toList(),
      );
      _saveFavIdListsToStorage();
      log('FavoritesController ($instanceId) fetched ${collars.length} favorite COLLARS.');
    } catch (e) {
      collarError.value = 'Failed to load favorite collars: $e';
      log('Error fetching favorite collars: $e');
    } finally {
      isLoadingCollars.value = false;
    }
  }

  Future<void> fetchFavoriteProducts({bool force = false}) async {
    if (!force && favoriteProducts.isNotEmpty && !isLoadingProducts.value) return;

    log('FavoritesController ($instanceId) fetching favorite PRODUCTS...');
    try {
      isLoadingProducts.value = true;
      productError.value = '';
      final products = await FavService().getProductFavList();
      favoriteProducts.assignAll(products);
      favProductListIds.assignAll(
        products.map((e) => {'id': e.id, 'name': e.name ?? ''}).toList(),
      );
      _saveFavIdListsToStorage();
      log('FavoritesController ($instanceId) fetched ${products.length} favorite PRODUCTS.');
    } catch (e) {
      productError.value = 'Failed to load favorite products: $e';
      log('Error fetching favorite products: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> addFavorite({required int id, required String name, required bool isCollar, ProductModel? product}) async {
    log('FavoritesController ($instanceId) attempting to ADD favorite: id=$id, isCollar=$isCollar');
    final future = isCollar ? FavService().addCollarToFav(id: id) : FavService().addProductToFav(id: id);

    try {
      final response = await future;

      if (response == 201 || response == 200) {
        log('FavoritesController ($instanceId) API ADD success (Code: $response)');
        showSnackBar('copySucces'.tr, isCollar ? 'collarAddToFav'.tr : 'productAddToFav'.tr, ColorConstants.greenColor);

        final newItemIdData = {'id': id, 'name': name};

        bool idListUpdated = false;
        if (isCollar) {
          if (!favCollarListIds.any((element) => element['id'] == id)) {
            favCollarListIds.add(newItemIdData);

            if (product != null && !favoriteCollars.any((p) => p.id == id)) {
              favoriteCollars.add(product);
            } else {
              fetchFavoriteCollars(force: true);
            }
            idListUpdated = true;
            log('FavoritesController ($instanceId) Added COLLAR id $id to favCollarListIds. New length: ${favCollarListIds.length}');
          } else {
            log('FavoritesController ($instanceId) COLLAR id $id already in favCollarListIds.');
          }
        } else {
          if (!favProductListIds.any((element) => element['id'] == id)) {
            favProductListIds.add(newItemIdData);

            if (product != null && !favoriteProducts.any((p) => p.id == id)) {
              favoriteProducts.add(product);
            } else {
              fetchFavoriteProducts(force: true);
            }
            idListUpdated = true;
            log('FavoritesController ($instanceId) Added PRODUCT id $id to favProductListIds. New length: ${favProductListIds.length}');
          } else {
            log('FavoritesController ($instanceId) PRODUCT id $id already in favProductListIds.');
          }
        }

        if (idListUpdated) {
          _saveFavIdListsToStorage();
        }
      } else {
        log('FavoritesController ($instanceId) API ADD failed (Code: $response)');
        showSnackBar('error'.tr, 'Failed to add favorite (Code: $response)', ColorConstants.redColor);
      }
    } catch (e) {
      log('FavoritesController ($instanceId) Exception during ADD favorite: $e');
      showSnackBar('error'.tr, 'Failed to add favorite: $e', ColorConstants.redColor);
    }
  }

  Future<void> removeFavorite({required int id, required bool isCollar}) async {
    log('FavoritesController ($instanceId) attempting to REMOVE favorite: id=$id, isCollar=$isCollar');
    final future = isCollar ? FavService().deleteCollarToFav(id: id) : FavService().deleteProductToFav(id: id);

    try {
      final response = await future;

      if (response == 204 || response == 200) {
        log('FavoritesController ($instanceId) API REMOVE success (Code: $response)');
        showSnackBar('copySucces'.tr, isCollar ? 'deleteCollar'.tr : 'deleteProduct'.tr, ColorConstants.redColor);

        bool listUpdated = false;
        if (isCollar) {
          final int initialLength = favCollarListIds.length;
          favCollarListIds.removeWhere((element) => element['id'] == id);
          if (favCollarListIds.length < initialLength) {
            log('FavoritesController ($instanceId) Removed COLLAR id $id from favCollarListIds. New length: ${favCollarListIds.length}');
            listUpdated = true;
          }

          favoriteCollars.removeWhere((product) => product.id == id);
        } else {
          final int initialLength = favProductListIds.length;
          favProductListIds.removeWhere((element) => element['id'] == id);
          if (favProductListIds.length < initialLength) {
            log('FavoritesController ($instanceId) Removed PRODUCT id $id from favProductListIds. New length: ${favProductListIds.length}');
            listUpdated = true;
          }

          favoriteProducts.removeWhere((product) => product.id == id);
        }

        if (listUpdated) {
          _saveFavIdListsToStorage();
        }
      } else {
        log('FavoritesController ($instanceId) API REMOVE failed (Code: $response)');
        showSnackBar('error'.tr, 'Failed to remove favorite (Code: $response)', ColorConstants.redColor);
      }
    } catch (e) {
      log('FavoritesController ($instanceId) Exception during REMOVE favorite: $e');
      showSnackBar('error'.tr, 'Failed to remove favorite: $e', ColorConstants.redColor);
    }
  }

  void _saveFavIdListsToStorage() async {
    try {
      final productJson = jsonEncode(favProductListIds.toList());
      final collarJson = jsonEncode(favCollarListIds.toList());
      log('FavoritesController ($instanceId) SAVING favProductListIds ($productJson) and favCollarListIds ($collarJson) to storage.');
      await storage.write('favProductListIds', productJson);
      await storage.write('favCollarListIds', collarJson);
      log('FavoritesController ($instanceId) SAVED favorite ID lists to storage.');
    } catch (e) {
      log('FavoritesController ($instanceId) Error SAVING favorite ID lists: $e');
    }
  }

  void _loadFavIdListsFromStorage() {
    log('FavoritesController ($instanceId) LOADING favorite ID lists from storage...');
    final String? productJson = storage.read('favProductListIds');
    final String? collarJson = storage.read('favCollarListIds');
    log('FavoritesController ($instanceId) Raw Product JSON from storage: $productJson');
    log('FavoritesController ($instanceId) Raw Collar JSON from storage: $collarJson');

    if (productJson != null) {
      try {
        final decodedProducts = List<Map<String, dynamic>>.from(jsonDecode(productJson));
        favProductListIds.assignAll(decodedProducts);
        log('FavoritesController ($instanceId) LOADED ${favProductListIds.length} Product IDs.');
      } catch (e) {
        log('FavoritesController ($instanceId) Error decoding favProductListIds: $e. Clearing stored value.');
        storage.remove('favProductListIds');
        favProductListIds.clear();
      }
    } else {
      log('FavoritesController ($instanceId) No Product IDs found in storage.');
      favProductListIds.clear();
    }

    if (collarJson != null) {
      try {
        final decodedCollars = List<Map<String, dynamic>>.from(jsonDecode(collarJson));
        favCollarListIds.assignAll(decodedCollars);
        log('FavoritesController ($instanceId) LOADED ${favCollarListIds.length} Collar IDs.');
      } catch (e) {
        log('FavoritesController ($instanceId) Error decoding favCollarListIds: $e. Clearing stored value.');
        storage.remove('favCollarListIds');
        favCollarListIds.clear();
      }
    } else {
      log('FavoritesController ($instanceId) No Collar IDs found in storage.');
      favCollarListIds.clear();
    }
  }

  void clearAllFavoritesLocal() {
    log('FavoritesController ($instanceId) Clearing all local favorites data.');
    favoriteCollars.clear();
    favoriteProducts.clear();
    favCollarListIds.clear();
    favProductListIds.clear();
    _saveFavIdListsToStorage();
  }
}
