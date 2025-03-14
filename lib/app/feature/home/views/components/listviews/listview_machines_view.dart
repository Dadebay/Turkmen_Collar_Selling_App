import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/cards/machine_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class ListviewMachinesView extends GetView {
  ListviewMachinesView({Key? key}) : super(key: key);
  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future: homeController.getMachines,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CardsLoading(loaderType: LoaderType.machine);
        } else if (snapshot.hasError) {
          return SizedBox.shrink();
        } else if (snapshot.data!.isEmpty) {
          return EmptyState(name: 'emptyMachinesSubtitle', type: EmptyStateType.text);
        }
        return SizedBox(
          height: WidgetSizes.size256.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomWidgets.listViewBuilderName(
                text: 'machines',
                context: context,
                showIcon: false,
                onTap: () {},
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return MachineCard(
                      productModel: snapshot.data![index],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
