import 'package:flutter/material.dart';

import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/phone_number_text_field.dart';
import '../../../../core/icons/app_icon.dart';

class ProfilSettingsPage extends StatefulWidget {
  const ProfilSettingsPage({super.key});

  @override
  State<ProfilSettingsPage> createState() => _ProfilSettingsPageState();
}

class _ProfilSettingsPageState extends State<ProfilSettingsPage> {
  final TextEditingController userNameController = TextEditingController();
  final FocusNode userNameFocusNode = FocusNode();
  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final TextEditingController userSurnameController = TextEditingController();
  final FocusNode userSurnameFocusNode = FocusNode();
  final String balance = '0.0';

  @override
  void initState() {
    super.initState();
    userNameController.text = 'Yok';
    userSurnameController.text = 'Yok';
  }

  @override
  void dispose() {
    userNameController.dispose();
    userNameFocusNode.dispose();
    phoneController.dispose();
    phoneFocusNode.dispose();
    userSurnameController.dispose();
    userSurnameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: AppIcon(IconlyLight.arrowLeftCircle, color: appBarForeground),
        ),
        title: Text(
          'profil'.tr,
          style: TextStyle(color: appBarForeground, fontSize: 18),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          textpart(context, 'signIn1', false),
          CustomTextField(
            labelName: '',
            controller: userNameController,
            focusNode: userNameFocusNode,
            requestfocusNode: phoneFocusNode,
            isNumber: false,
          ),
          textpart(context, 'signIn2', false),
          CustomTextField(
            labelName: '',
            controller: userSurnameController,
            focusNode: userSurnameFocusNode,
            requestfocusNode: phoneFocusNode,
            isNumber: false,
          ),
          textpart(context, 'phoneNumber', false),
          PhoneNumberTextField(
            mineFocus: phoneFocusNode,
            controller: phoneController,
            requestFocus: userNameFocusNode,
            disabled: true,
          ),
          textpart(context, 'balance', false),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${'balance'.tr} :', style: const TextStyle(fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(balance, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          AgreeButton(onTap: () {}),
        ],
      ),
    );
  }
}
