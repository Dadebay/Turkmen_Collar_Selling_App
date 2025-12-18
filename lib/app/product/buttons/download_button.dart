import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/auth/views/user_login_view.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/payment/controllers/payment_status_controller.dart';
import 'package:yaka2/app/feature/product_profil/views/download_yaka.dart';
import 'package:yaka2/app/product/buttons/add_cart_button.dart';
import 'package:yaka2/app/product/constants/index.dart';

class DownloadButton extends StatelessWidget {
  final ProductModel productModel;
  final bool makeBigger;
  const DownloadButton({required this.productModel, required this.makeBigger, super.key});

  @override
  Widget build(BuildContext context) {
    // Check payment status - if disabled, show AddCartButton instead
    final paymentStatusController = Get.find<PaymentStatusController>();

    if (paymentStatusController.isPaymentDisabled.value) {
      // Payment disabled - show cart button (for Apple Store compliance)
      return AddCartButton(
        productModel: productModel,
        productProfilDesign: makeBigger,
      );
    }

    // Payment enabled - show download button
    return GestureDetector(
      onTap: () async {
        final token = await Auth().getToken();
        if (token == null) {
          showSnackBar('loginError', 'loginErrorSubtitle1', ColorConstants.redColor);
          await Get.to(() => UserLoginView());
        } else {
          await Get.to(
            () => DownloadYakaPage(
              image: productModel.image,
              id: productModel.id,
              pageName: productModel.name,
            ),
          );
        }
      },
      child: Container(
        width: Get.size.width,
        margin: makeBigger ? context.padding.normal : const EdgeInsets.only(top: 4),
        padding: EdgeInsets.symmetric(vertical: makeBigger ? 8 : 4),
        decoration: BoxDecoration(
          borderRadius: context.border.lowBorderRadius,
          color: ColorConstants.primaryColor,
        ),
        child: Text(
          'download'.tr,
          textAlign: TextAlign.center,
          style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.whiteColor, fontSize: makeBigger ? 23 : 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
