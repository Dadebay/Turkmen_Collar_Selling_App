import 'package:get/get.dart';

import '../constants/index.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: context.padding.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(IconConstants.emptyCart, width: WidgetSizes.size350.value, height: WidgetSizes.size350.value),
            Text(
              'cartEmpty'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'cartEmptySubtitle'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorConstants.blackColor, //fontFamily: normProBold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
