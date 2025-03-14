import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaka2/app/feature/auth/models/auth_model.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/views/instruction_page/instruction_page.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:yaka2/app/product/utils/custom_bottom_nav_extension.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

class BottomNavBar extends StatefulWidget {
  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int selectedIndex = 0;
  final BalanceController balanceController = Get.put<BalanceController>(BalanceController());
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
    _checkLoginStatus();
    _startBalanceTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startBalanceTimer() {
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      log('user money updated ${balanceController.balance.value}');
      balanceController.userMoney();
    });
  }

  void _checkNotificationPermission() async {
    await AboutUsService().getAboutUs();
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus != PermissionStatus.granted) {
      DialogUtils().showNotificationPermissionDialog(context);
    }
  }

  void _checkLoginStatus() {
    bool isDialogShowing = false;
    timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final String? isLoggedIn = await Auth().getToken() ?? '';
      if (isLoggedIn!.isEmpty || isLoggedIn == 'null') {
        if (!isDialogShowing) {
          isDialogShowing = true;
          DialogUtils().showLoginDialogMine(context);
        }
      } else {
        timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedIndex == 1
          ? null
          : CustomAppBar(
              title: ListConstants.pageNames[selectedIndex],
              showBackButton: false,
              showWallet: true,
            ),
      body: ListConstants.pages[selectedIndex],
      floatingActionButton: selectedIndex == 2 ? null : _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // balanceController.userMoney();
        Get.to(() => const InstructionPage());
      },
      backgroundColor: ColorConstants.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: context.border.highBorderRadius),
      child: const Icon(Icons.question_mark_outlined, color: ColorConstants.whiteColor),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomNavBar(
      selectedIcons: ListConstants.selectedIcons,
      unselectedIcons: ListConstants.mainIcons,
      currentIndex: selectedIndex,
      onTap: (index) => setState(() => selectedIndex = index),
    );
  }
}
