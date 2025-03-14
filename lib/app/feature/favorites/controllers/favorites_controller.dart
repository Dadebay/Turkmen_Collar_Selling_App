import 'dart:convert';

import 'package:get/get.dart';
import 'package:yaka2/app/feature/favorites/services/fav_service.dart';

import '../../../product/constants/index.dart';

class FavoritesController extends GetxController {
  final RxList favList = [].obs;
  final storage = GetStorage();

  dynamic addCollarFavList(int id, String name) async {
    await FavService().addCollarToFav(id: id).then((value) {
      if (value == 201) {
        showSnackBar('copySucces', 'collarAddToFav', ColorConstants.greenColor);
        favList.add({'id': id, 'name': name});
      } else {
        showSnackBar('noConnection3', 'error', ColorConstants.redColor);
      }
    });
    favList.refresh();
    final String jsonString = jsonEncode(favList);
    await storage.write('favList', jsonString);
  }

  dynamic removeCollarFavList(int id) async {
    await FavService().deleteCollarToFav(id: id).then((value) {
      if (value == 204) {
        favList.removeWhere((element) => element['id'] == id);
        showSnackBar('copySucces', 'deleteCollar', ColorConstants.redColor);
      } else {
        showSnackBar('noConnection3', 'error', ColorConstants.redColor);
      }
    });
    favList.refresh();
    final String jsonString = jsonEncode(favList);
    await storage.write('favList', jsonString);
  }

////////////////////////////////////////////////////////////
  dynamic addProductFavList(int id, String name) async {
    await FavService().addProductToFav(id: id).then((value) {
      if (value == 201) {
        showSnackBar('copySucces', 'productAddToFav', ColorConstants.greenColor);
        favList.add({'id': id, 'name': name});
      } else {
        showSnackBar('noConnection3', 'error', ColorConstants.redColor);
      }
    });
    favList.refresh();
    final String jsonString = jsonEncode(favList);
    await storage.write('favList', jsonString);
  }

  dynamic removeProductFavList(int id) async {
    await FavService().deleteProductToFav(id: id).then((value) {
      if (value == 204) {
        favList.removeWhere((element) => element['id'] == id);
        showSnackBar('copySucces', 'deleteProduct', ColorConstants.redColor);
      } else {
        showSnackBar('noConnection3', 'error', ColorConstants.redColor);
      }
    });
    favList.refresh();
    final String jsonString = jsonEncode(favList);
    await storage.write('favList', jsonString);
  }

  dynamic clearFavList() {
    favList.clear();
    final String jsonString = jsonEncode(favList);
    storage.write('favList', jsonString);
  }
}
