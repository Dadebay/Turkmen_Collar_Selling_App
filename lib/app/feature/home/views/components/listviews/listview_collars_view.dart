import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/collars_controller.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/utils/packages_index.dart';

class ListviewCollarsView extends StatelessWidget {
  final CollarController collarController = Get.put(CollarController());
  ListviewCollarsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WidgetSizes.size350.value + 30,
      child: Obx(() {
        if (collarController.collarLoading.value == 0) {
          return CardsLoading(loaderType: LoaderType.collar);
        } else if (collarController.collarLoading.value == 1) {
          return EmptyState(name: 'noProductFound', type: EmptyStateType.text);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomWidgets.listViewBuilderName(
              text: 'collars',
              context: context,
              showIcon: false,
              onTap: () {},
            ),
            Expanded(
              child: SmartRefresher(
                footer: footer(),
                controller: collarController.refreshController,
                onLoading: collarController.collarOnLoading,
                enablePullDown: false,
                enablePullUp: true,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
                child: ListView.builder(
                  itemCount: collarController.collarList.length,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ProductCard(product: collarController.collarList[index]);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
