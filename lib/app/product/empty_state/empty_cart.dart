import 'package:get/get.dart';

import '../constants/index.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/emptyCART.json', width: 350, height: 350),
            Text(
              'cartEmpty'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorConstants.blackColor, //fontFamily: normProBold,
                fontSize: 20,
              ),
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
