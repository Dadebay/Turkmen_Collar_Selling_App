import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/clothes_controller.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class ListviewClothesView extends GetView {
  final ClothesController clothesController = Get.find();
  ListviewClothesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WidgetSizes.size350.value,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomWidgets.listViewBuilderName(
            text: 'womenClothes',
            context: context,
            onTap: () {},
            showIcon: false,
          ),
          Expanded(
            child: SmartRefresher(
              footer: footer(),
              controller: clothesController.refreshController,
              onLoading: clothesController.onLoading,
              enablePullDown: false,
              enablePullUp: true,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
              child: Obx(
                () {
                  print(clothesController.clothesLoading.value);
                  print(clothesController.clothesList.length);
                  if (clothesController.clothesLoading.value == 0) {
                    return CardsLoading(loaderType: LoaderType.collar);
                  } else if (clothesController.clothesLoading.value == 1) {
                    return ErrorState(onTap: () => clothesController.getData());
                  } else if (clothesController.clothesLoading.value == 2) {
                    return EmptyState(name: 'noProductFound', type: EmptyStateType.text);
                  }
                  print(clothesController.clothesLoading.value);
                  print(clothesController.clothesList.length);
                  return ListView.builder(
                    itemCount: clothesController.clothesList.length,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (BuildContext context, int index) {
                      return ProductCard(product: clothesController.clothesList[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
