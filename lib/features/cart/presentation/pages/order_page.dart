// ignore_for_file: always_put_control_body_on_new_line
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/list_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/phone_number_text_field.dart';
import '../../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../../../../core/icons/app_icon.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final FocusNode orderAdressFocusNode = FocusNode();
  final FocusNode orderUserName = FocusNode();
  final FocusNode orderPhoneNumber = FocusNode();
  final FocusNode orderNote = FocusNode();
  final orderPageKey = GlobalKey<FormState>();

  String name = 'Asgabat';

  @override
  void dispose() {
    userNameController.dispose();
    noteController.dispose();
    addressController.dispose();
    phoneController.dispose();
    orderAdressFocusNode.dispose();
    orderUserName.dispose();
    orderPhoneNumber.dispose();
    orderNote.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(orderPageKey.currentState?.validate() ?? false)) {
      showSnackBar(
        context,
        'noConnection3',
        'errorEmpty',
        ColorConstants.redColor,
      );
      return;
    }
    // App-Store-compliant bypass: when payments are disabled the backend doesn't
    // accept orders, so we clear the cart locally and report success. Matches
    // main's OrderService.createOrder behaviour.
    if (context.read<PaymentStatusBloc>().state.isDisabled) {
      context.read<CartBloc>().add(const CartCleared());
      showSnackBar(
        context,
        'copySuccess',
        'orderSubtitle',
        ColorConstants.greenColor,
      );
      context.go(AppRoutes.home);
      return;
    }
    context.read<CartBloc>().add(
      CartOrderPlaced(
        userName: userNameController.text,
        address: addressController.text,
        city: name,
        note: noteController.text,
        phone: phoneController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartOrderSuccess) {
          showSnackBar(
            context,
            'copySuccess',
            'orderSubtitle',
            ColorConstants.greenColor,
          );
          context.go(AppRoutes.home);
        } else if (state is CartOrderError) {
          showSnackBar(
            context,
            'noConnection3',
            'error',
            ColorConstants.redColor,
          );
        }
      },
      child: SafeArea(
        bottom: true,
        top: false,
        child: Scaffold(
          appBar: const CustomAppBar(
            title: 'orderProducts',
            showBackButton: true,
          ),
          body: Form(
            key: orderPageKey,
            child: ListView(
              padding: context.padding.normal,
              children: [
                textpart(context, 'userName', true),
                CustomTextField(
                  labelName: 'userName',
                  controller: userNameController,
                  focusNode: orderUserName,
                  requestfocusNode: orderPhoneNumber,
                  isNumber: false,
                  maxline: 1,
                ),
                textpart(context, 'phoneNumber', false),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: PhoneNumberTextField(
                    mineFocus: orderPhoneNumber,
                    controller: phoneController,
                    requestFocus: orderAdressFocusNode,
                  ),
                ),
                textpart(context, 'selectCityTitle', true),
                _selectCity(context),
                textpart(context, 'orderAdress', false),
                CustomTextField(
                  labelName: 'orderAdress',
                  controller: addressController,
                  focusNode: orderAdressFocusNode,
                  requestfocusNode: orderNote,
                  isNumber: false,
                  maxline: 4,
                ),
                textpart(context, 'note', false),
                CustomTextField(
                  labelName: 'note',
                  controller: noteController,
                  focusNode: orderNote,
                  requestfocusNode: orderUserName,
                  isNumber: false,
                  maxline: 4,
                ),
                const SizedBox(height: 40),
                Center(
                  child: BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      return AgreeButton(
                        onTap: _submit,
                        isLoading: state is CartOrdering,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _selectCity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        title: Text(
          name.tr,
          style: TextStyle(color: AppPalette.of(context).text, fontSize: 18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: context.border.normalBorderRadius,
          side: BorderSide(color: AppPalette.of(context).muted),
        ),
        tileColor: AppPalette.of(context).surface,
        trailing: const AppIcon(IconlyLight.arrowRightCircle),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              backgroundColor: AppPalette.of(context).surface,
              title: Text(
                'selectCityTitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.of(context).text),
              ),
              titlePadding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                          if (!mounted) return;
                          setState(() {});
                          Navigator.of(dialogCtx).pop();
                        },
                        child: Text(
                          ListConstants.cities[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppPalette.of(context).text,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
