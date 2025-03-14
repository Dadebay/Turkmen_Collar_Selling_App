import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/goods_controller.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class ListViewGoods extends GetView {
  final GoodsController goodsController = Get.find();

  ListViewGoods({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WidgetSizes.size350.value,
      child: Obx(
        () {
          if (goodsController.goodsLoading.value == 0) {
            return CardsLoading(loaderType: LoaderType.collar);
          } else if (goodsController.goodsLoading.value == 1) {
            return ErrorState(onTap: () => goodsController.goodsOnRefresh());
          } else if (goodsController.goodsLoading.value == 2) {
            return EmptyState(name: 'noProductFound', type: EmptyStateType.text);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomWidgets.listViewBuilderName(
                text: 'listview_goods',
                context: context,
                onTap: () {},
                showIcon: false,
              ),
              Expanded(
                child: SmartRefresher(
                  footer: footer(),
                  controller: goodsController.refreshController,
                  onLoading: goodsController.goodsOnLoading,
                  enablePullDown: false,
                  enablePullUp: true,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
                  child: ListView.builder(
                    shrinkWrap: true,
                    addAutomaticKeepAlives: true,
                    itemCount: goodsController.goodsList.length,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return ProductCard(product: goodsController.goodsList[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
