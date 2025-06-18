import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/collars_controller.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/utils/packages_index.dart';

class ListviewCollarsView extends StatefulWidget {
  ListviewCollarsView({Key? key}) : super(key: key);

  @override
  State<ListviewCollarsView> createState() => _ListviewCollarsViewState();
}

class _ListviewCollarsViewState extends State<ListviewCollarsView> {
  final CollarController collarController = Get.put(CollarController());

  final RefreshController listviewRefreshController = RefreshController();

  @override
  void dispose() {
    listviewRefreshController.dispose();
    super.dispose();
  }

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
                controller: listviewRefreshController,
                onLoading: () async {
                  await collarController.collarOnLoading();
                  listviewRefreshController.loadComplete();
                },
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
