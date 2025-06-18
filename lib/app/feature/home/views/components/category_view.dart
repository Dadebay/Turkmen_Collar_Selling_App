import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/models/category_model.dart';
import 'package:yaka2/app/feature/home/services/category_service.dart';
import 'package:yaka2/app/feature/home/views/show_all_products_view.dart';
import 'package:yaka2/app/product/constants/index.dart';

class CategoryView extends GetView {
  @override
  final HomeController controller = Get.put(HomeController());
  CategoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: controller.getCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MiniCategoryLoading();
        } else if (snapshot.hasError) {
          return ErrorState(onTap: () => CategoryService().getCategories());
        } else if (snapshot.data?.isEmpty ?? true) {
          return SizedBox.shrink();
        }
        print(snapshot.data!);
        print(snapshot.data!.length);
        String image = '';
        CategoryModel? categoryModel;
        snapshot.data!.asMap().forEach((i, cat) {
          if (cat.name == 'Ýakalar') {
            image = cat.image;
            categoryModel = cat;
          }
        });

        return Column(
          children: [
            buildCarousel(snapshot.data!),
            GestureDetector(
              onTap: () {
                final CategoryModel categories = categoryModel!;
                Get.to(() => ShowAllProductsView(categoryModel: categories));
              },
              child: Container(
                width: Get.size.width,
                height: 220,
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: CustomWidgets.customImageView(image: image, cover: true, borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildCarousel(List<CategoryModel> categories) {
    return CarouselSlider.builder(
      itemCount: (categories.length / 4).ceil(),
      itemBuilder: (context, index, _) {
        return buildCategoryGrid(categories, index, context);
      },
      options: CarouselOptions(
        height: WidgetSizes.size300.value,
        viewportFraction: 1.0,
        autoPlay: true,
        enableInfiniteScroll: true,
        scrollPhysics: const BouncingScrollPhysics(),
        autoPlayCurve: Curves.fastLinearToSlowEaseIn,
        autoPlayAnimationDuration: const Duration(seconds: 4),
      ),
    );
  }

  Widget buildCategoryGrid(List<CategoryModel> categories, int index, BuildContext context) {
    final startIndex = index * 4;
    final endIndex = (startIndex + 4).clamp(0, categories.length);

    return Column(
      children: List.generate(2, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(2, (colIndex) {
              final categoryIndex = startIndex + (rowIndex * 2) + colIndex;
              return Expanded(
                child: categoryIndex < endIndex
                    ? GestureDetector(
                        onTap: () => Get.to(() => ShowAllProductsView(categoryModel: categories[categoryIndex])),
                        child: Padding(
                          padding: context.padding.low,
                          child: CustomWidgets.customImageView(image: categories[categoryIndex].image, cover: true, borderRadius: CustomBorderRadius.lowBorderRadius),
                        ),
                      )
                    : Container(),
              );
            }),
          ),
        );
      }),
    );
  }
}
