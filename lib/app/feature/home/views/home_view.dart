// ignore_for_file: always_declare_return_types
//
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/views/components/banners_view.dart';
import 'package:yaka2/app/feature/home/views/components/category_view.dart';
import 'package:yaka2/app/feature/home/views/components/listviews/listview_clothes_view.dart';
import 'package:yaka2/app/feature/home/views/components/listviews/listview_collars_view.dart';
import 'package:yaka2/app/feature/home/views/components/listviews/listview_goods.dart';
import 'package:yaka2/app/feature/home/views/components/listviews/listview_machines_view.dart';
import 'package:yaka2/app/product/constants/index.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final RefreshController refreshController = RefreshController(initialRefresh: false);
  final HomeController homeController = Get.put(HomeController());

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    refreshController.refreshCompleted();
    homeController.getProducts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      footer: footer(),
      controller: refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      onLoading: null,
      header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
      child: ListView(
        children: [
          BannersView(),
          CategoryView(),
          Obx(() {
            return Column(
              children: [
                // if (homeController.collarController.collarList.isNotEmpty) ListviewCollarsView(),
                if (homeController.clothesController.clothesList.isNotEmpty) ListviewClothesView(),
                if (homeController.goodsController.goodsList.isNotEmpty) ListViewGoods(),
              ],
            );
          }),
          FutureBuilder<List<ProductModel>>(
            future: homeController.getMachines,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListviewMachinesView();
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
