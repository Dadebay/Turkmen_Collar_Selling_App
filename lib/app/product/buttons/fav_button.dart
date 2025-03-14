import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/favorites/controllers/favorites_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../feature/auth/views/user_login_view.dart';

class FavButton extends StatefulWidget {
  final int id;
  final bool isCollar;
  final String name;
  final bool? changeBackColor;
  const FavButton({
    required this.isCollar,
    required this.id,
    required this.name,
    this.changeBackColor,
    super.key,
  });

  @override
  State<FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<FavButton> {
  final FavoritesController favoritesController = Get.put(FavoritesController());
  bool value = false;

  @override
  void initState() {
    super.initState();
    work();
  }

  dynamic work() {
    for (var element in favoritesController.favList) {
      if (element['id'] == widget.id && element['name'] == widget.name) {
        value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        work();

        return GestureDetector(
          onTap: () async {
            final token = await Auth().getToken();
            if (token == null || token == '') {
              showSnackBar('loginError', 'loginErrorSubtitle1', ColorConstants.redColor);
              await Get.to(() => UserLoginView());
            } else {
              if (widget.isCollar) {
                if (!value) {
                  favoritesController.addCollarFavList(widget.id, widget.name);
                } else {
                  favoritesController.removeCollarFavList(widget.id);
                }
              }
              if (!widget.isCollar) {
                if (!value) {
                  favoritesController.addProductFavList(widget.id, widget.name);
                } else {
                  favoritesController.removeProductFavList(widget.id);
                }
              }

              value = !value;
              setState(() {});
            }
          },
          child: Container(
            padding: context.padding.low,
            decoration: BoxDecoration(
              borderRadius: CustomBorderRadius.normalBorderRadius,
              color: widget.changeBackColor == true ? ColorConstants.primaryColor : ColorConstants.whiteColor,
            ),
            child: Icon(
              value ? IconlyBold.heart : IconlyLight.heart,
              color: value
                  ? ColorConstants.redColor
                  : widget.changeBackColor == true
                      ? ColorConstants.whiteColor
                      : ColorConstants.blackColor,
            ),
          ),
        );
      },
    );
  }
}
