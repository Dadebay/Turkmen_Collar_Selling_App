import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/models/category_model.dart';
import 'package:yaka2/app/feature/home/views/show_all_products_view.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarouselItem {
  CarouselItem({required this.name, this.image, required this.onTap});

  final String? image;
  final String name;
  final VoidCallback onTap;
}

class CategoryView extends StatefulWidget {
  CategoryView({Key? key}) : super(key: key);

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final HomeController controller = Get.put(HomeController());

  Widget buildCarousel(List<CarouselItem> items) {
    if (items.isEmpty) {
      return SizedBox.shrink();
    }
    return CarouselSlider.builder(
      itemCount: (items.length / 4).ceil(),
      itemBuilder: (context, index, _) {
        return buildCategoryGrid(items, index, context);
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

  Widget buildYakalarBanner(CategoryModel categoryModel) {
    String image = categoryModel.image ?? '';
    return GestureDetector(
      onTap: () {
        Get.to(() => ShowAllProductsView(categoryModel: categoryModel));
      },
      child: Container(
        width: Get.size.width,
        height: 220,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: CachedNetworkImage(
          fadeInCurve: Curves.ease,
          imageUrl: image,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: imageProvider,
                alignment: Alignment.topCenter,
                fit: BoxFit.fill,
              ),
            ),
          ),
          placeholder: (context, url) => Loading(),
          errorWidget: (context, url, error) => NoImage(),
        ),
      ),
    );
  }

  Widget buildCategoryGrid(List<CarouselItem> items, int pageIndex, BuildContext context) {
    final startIndex = pageIndex * 4;
    return Column(
      children: List.generate(2, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(2, (colIndex) {
              final itemIndex = startIndex + (rowIndex * 2) + colIndex;
              if (itemIndex >= items.length) {
                return Expanded(child: Container());
              }
              final item = items[itemIndex];
              return Expanded(
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Padding(
                    padding: context.padding.low,
                    child: (item.image != null && item.image!.isNotEmpty)
                        ? CachedNetworkImage(
                            fadeInCurve: Curves.ease,
                            imageUrl: item.image!,
                            imageBuilder: (context, imageProvider) => Container(
                              padding: EdgeInsets.zero,
                              width: Get.size.width,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: CustomBorderRadius.lowBorderRadius,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Loading(),
                            errorWidget: (context, url, error) => Text(item.name),
                          )
                        : Container(
                            decoration: BoxDecoration(color: ColorConstants.greyColor.withOpacity(.2), borderRadius: CustomBorderRadius.lowBorderRadius),
                            child: Center(child: Text(item.name, style: const TextStyle(color: ColorConstants.blackColor, fontWeight: FontWeight.bold)))),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Future<List<dynamic>> _fetchAllData() {
    return Future.wait([
      controller.getCategories,
      AboutUsService().getFilterElements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MiniCategoryLoading();
        } else if (snapshot.hasError) {
          return ErrorState(onTap: () => setState(() {}));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        final mainCategories = snapshot.data![0] as List<CategoryModel>;
        final subCategories = snapshot.data![1] as List<GetFilterElements>;
        final yakalarCategory = mainCategories.firstWhereOrNull((cat) => cat.name == 'Ýakalar');
        final List<CarouselItem> allItems = [];

        allItems.addAll(mainCategories.map((cat) => CarouselItem(
              name: cat.name ?? '',
              image: cat.image,
              onTap: () => Get.to(() => ShowAllProductsView(categoryModel: cat)),
            )));

        if (yakalarCategory != null) {
          allItems.addAll(subCategories.map((subCat) {
            final subCatIndex = subCategories.indexOf(subCat);
            return CarouselItem(
              name: subCat.name ?? '',
              image: subCat.image,
              onTap: () => Get.to(() => ShowAllProductsView(
                    categoryModel: yakalarCategory,
                    subCatId: subCat.id,
                    subCatIndex: subCatIndex,
                  )),
            );
          }));
        }

        CategoryModel? mainYakalar = mainCategories.firstWhereOrNull((cat) => cat.name == 'Ýakalar');
        mainYakalar ??= mainCategories.isNotEmpty ? mainCategories.first : null;

        if (mainYakalar == null) {
          return buildCarousel(allItems);
        }

        return Wrap(
          children: [
            buildCarousel(allItems),
            buildYakalarBanner(mainYakalar),
          ],
        );
      },
    );
  }
}
