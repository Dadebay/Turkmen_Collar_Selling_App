import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../features/home/domain/entities/product_entity.dart';
import '../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../../l10n/app_translations.dart';
import '../../router/app_router.dart';
import '../../theme/color_constants.dart';
import '../../theme/context_extensions.dart';
import 'add_cart_button.dart';

class DownloadButton extends StatelessWidget {
  final ProductEntity productModel;
  final bool makeBigger;

  const DownloadButton({
    required this.productModel,
    required this.makeBigger,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PaymentStatusBloc, PaymentStatusState, bool>(
      selector: (state) => state.isDisabled,
      builder: (context, paymentsDisabled) {
        // Apple-Store-compliant fallback: when payments are disabled the
        // download CTA is replaced by an add-to-cart button (matches main).
        if (paymentsDisabled) {
          return AddCartButton(
            productModel: productModel,
            productProfilDesign: makeBigger,
          );
        }
        return GestureDetector(
          onTap: () => context.push(
            AppRoutes.downloadYakaPath(productModel.id),
            extra: {'image': productModel.image, 'pageName': productModel.name},
          ),
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            margin: makeBigger
                ? context.padding.normal
                : const EdgeInsets.only(top: 4),
            padding: EdgeInsets.symmetric(vertical: makeBigger ? 8 : 4),
            decoration: BoxDecoration(
              borderRadius: context.border.lowBorderRadius,
              color: ColorConstants.primaryColor,
            ),
            child: Text(
              'download'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.bodyLarge!.copyWith(
                color: Colors.white,
                fontSize: makeBigger ? 23 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
