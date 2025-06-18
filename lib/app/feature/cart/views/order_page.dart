import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/controllers/cart_controller.dart';
import 'package:yaka2/app/feature/cart/services/order_service.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/views/bottom_nav_bar_view.dart';
import 'package:yaka2/app/product/constants/index.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final HomeController signInPageController = Get.find();
  final CartController cartController = Get.put(CartController());
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final FocusNode orderAdressFocusNode = FocusNode();
  final FocusNode orderUserName = FocusNode();
  final FocusNode orderPhoneNumber = FocusNode();
  final FocusNode orderNote = FocusNode();
  final orderPage = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'orderProducts'.tr, showBackButton: true),
      body: Form(
        key: orderPage,
        child: ListView(
          padding: context.padding.normal,
          children: [
            textpart('userName', true),
            CustomTextField(
              labelName: 'userName',
              controller: userNameController,
              focusNode: orderUserName,
              requestfocusNode: orderPhoneNumber,
              isNumber: false,
              maxline: 1,
            ),
            textpart('phoneNumber', false),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: PhoneNumberTextField(
                mineFocus: orderPhoneNumber,
                controller: phoneController,
                requestFocus: orderAdressFocusNode,
              ),
            ),
            textpart('selectCityTitle', true),
            selectCity(context),
            textpart('orderAdress', false),
            CustomTextField(
              labelName: 'orderAdress',
              controller: addressController,
              focusNode: orderAdressFocusNode,
              requestfocusNode: orderNote,
              isNumber: false,
              maxline: 4,
            ),
            textpart('note', false),
            CustomTextField(
              labelName: 'note',
              controller: noteController,
              focusNode: orderNote,
              requestfocusNode: orderUserName,
              isNumber: false,
              maxline: 4,
            ),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: AgreeButton(
                onTap: () {
                  final List list = [];
                  if (orderPage.currentState!.validate()) {
                    for (var element in cartController.cartList) {
                      list.add({'id': element.id, 'quantity': element.quantity});
                    }
                    signInPageController.agreeButton.value = !signInPageController.agreeButton.value;
                    OrderService().createOrder(products: list, note: noteController.text, customerName: userNameController.text, address: addressController.text, province: name, phone: phoneController.text).then((value) {
                      if (value == true) {
                        showSnackBar('copySucces', 'orderSubtitle', ColorConstants.greenColor);
                        cartController.clearCart();
                        Get.to(() => BottomNavBar());
                      } else {
                        showSnackBar('noConnection3', 'error', ColorConstants.redColor);
                      }
                      signInPageController.agreeButton.value = !signInPageController.agreeButton.value;
                    });
                  } else {
                    showSnackBar('noConnection3', 'errorEmpty', ColorConstants.redColor);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String name = 'Asgabat';

  Padding selectCity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        title: Text(
          name.tr,
          style: const TextStyle(
            color: ColorConstants.blackColor,
            //fontFamily: normsProMedium,
            fontSize: 18,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: context.border.normalBorderRadius, side: BorderSide(color: ColorConstants.greyColor)),
        tileColor: ColorConstants.whiteColor,
        trailing: const Icon(IconlyLight.arrowRightCircle),
        onTap: () {
          Get.defaultDialog(
            title: 'selectCityTitle'.tr,
            titleStyle: const TextStyle(
              color: ColorConstants.blackColor,
            ), //fontFamily: normsProMedium),
            radius: 5,
            backgroundColor: ColorConstants.whiteColor,
            titlePadding: const EdgeInsets.symmetric(vertical: 20),
            content: Column(
              children: List.generate(
                ListConstants.cities.length,
                (index) => Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    divider(),
                    TextButton(
                      onPressed: () {
                        name = ListConstants.cities[index];
                        if (!mounted) {
                          return;
                        }
                        setState(() {});
                        Get.back();
                      },
                      child: Text(
                        '${ListConstants.cities[index]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ColorConstants.blackColor, //fontFamily: normsProMedium,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
