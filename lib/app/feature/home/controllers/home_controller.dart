import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/controllers/clothes_controller.dart';
import 'package:yaka2/app/feature/home/controllers/collars_controller.dart';
import 'package:yaka2/app/feature/home/controllers/goods_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/machines_service.dart';

import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../services/banner_service.dart';
import '../services/category_service.dart';

class HomeController extends GetxController {
  RxInt bannerDotsIndex = 0.obs;
  final CollarController collarController = Get.put(CollarController());
  final ClothesController clothesController = Get.put(ClothesController());
  final GoodsController goodsController = Get.put(GoodsController());
  late Future<List<BannerModel>> getBanners;
  late Future<List<ProductModel>> getMachines;
  late Future<List<CategoryModel>> getCategories;
  final BalanceController balanceController = Get.find();
  final Rx<bool> agreeButton = false.obs;
  @override
  void onInit() {
    super.onInit();

    getProducts();
  }

  dynamic getProducts() {
    getBanners = BannerService().getBanners();
    getCategories = CategoryService().getCategories();
    getMachines = MachineService().getMachines();
    goodsController.goodsOnRefresh();
    clothesController.collarOnRefresh();
    collarController.collarOnRefresh();
    balanceController.userMoney();
  }
}
