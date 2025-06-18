import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaka2/app/feature/auth/models/auth_model.dart';
import 'package:yaka2/app/feature/favorites/controllers/favorites_controller.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/views/instruction_page/instruction_page.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:yaka2/app/product/utils/custom_bottom_nav_extension.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

class BottomNavBar extends StatefulWidget {
  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with WidgetsBindingObserver {
  final BalanceController balanceController = Get.put<BalanceController>(BalanceController());
  Timer? balanceTimer;
  final GlobalKey fabKey = GlobalKey();
  final FavoritesController favoritesController = Get.put<FavoritesController>(FavoritesController());
  Timer? loginCheckTimer;
  int selectedIndex = 0;
  List<TargetFocus> targets = [];
  final UserProfilController userProfilController = Get.put(UserProfilController());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startBalanceTimer();
    } else if (state == AppLifecycleState.paused) {
      balanceTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    balanceTimer?.cancel();
    loginCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startBalanceTimer();
    _checkLoginStatus();

    // Uygulama başlatıldıktan sonra adımları sırayla kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeShowUpgradeDialog();
      await _maybeShowTutorial();

      await _maybeAskNotificationPermission();
    });
  }

  Future<void> _maybeShowUpgradeDialog() async {
    if (UpgradeAlert().upgrader.shouldDisplayUpgrade()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => UpgradeAlert(
          upgrader: Upgrader(languageCode: 'ru'),
          dialogStyle: Platform.isAndroid ? UpgradeDialogStyle.material : UpgradeDialogStyle.cupertino,
        ),
      );
    }
  }

  Future<void> _maybeShowTutorial() async {
    final box = GetStorage();
    final hasSeen = box.read('seen_fab_tutorial') ?? false;
    print(hasSeen);
    print(hasSeen);
    print(hasSeen);
    print(hasSeen);
    print(hasSeen);
    print(hasSeen);
    if (!hasSeen) {
      await Future.delayed(const Duration(milliseconds: 500)); // render sonrası
      _createTutorialTargets();
      _showTutorial();
      box.write('seen_fab_tutorial', true);
    }
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: 'Geç',
      onFinish: () => print('Tutorial tamamlandı'),
      onSkip: () => true,
    ).show(context: context);
  }

  void _startBalanceTimer() {
    balanceTimer?.cancel(); // varsa önce iptal et
    balanceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      log('user money updated ${balanceController.balance.value}');
      balanceController.userMoney();
    });
  }

  Future<void> _maybeAskNotificationPermission() async {
    final status = await Permission.notification.status;

    if (!status.isGranted) {
      await Future.delayed(Duration(seconds: 15));

      if (mounted) {
        DialogUtils.showLoginDialog(
          context: context,
          title: 'notificationTitle',
          agreeButton: 'giveAccess',
          subtitle: 'notificationSubtitle',
          image: IconConstants.loginLottie,
          onCancel: () => Get.back(),
          onRetry: () async {
            Get.back();
            await Future.delayed(Duration(milliseconds: 300));

            final newStatus = await Permission.notification.request();

            if (newStatus.isGranted) {
              // izin verildi
            } else if (newStatus.isPermanentlyDenied || newStatus.isDenied) {
              await openAppSettings(); // kullanıcıyı ayarlara yönlendir
            }
          },
        );
      }
    }
  }

  void _checkLoginStatus() {
    bool isDialogShowing = false;
    loginCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final String? isLoggedIn = await Auth().getToken() ?? '';
      if (isLoggedIn!.isEmpty || isLoggedIn == 'null') {
        if (!isDialogShowing) {
          isDialogShowing = true;
          DialogUtils().showLoginDialogMine(context);
        }
      } else {
        loginCheckTimer?.cancel();
      }
    });
  }

  void _createTutorialTargets() {
    targets.add(
      TargetFocus(
        identify: 'fab',
        keyTarget: fabKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programma barada ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dügmä basyň we programma ulanyşy barada wideolar görüň !',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Get.to(() => InstructionPage());
      },
      key: fabKey,
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
      onTap: (index) {
        setState(() => selectedIndex = index);
        balanceController.userMoney(); // anında tetikle
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        languageCode: 'ru',
      ),
      dialogStyle: Platform.isAndroid ? UpgradeDialogStyle.material : UpgradeDialogStyle.cupertino,
      child: Scaffold(
        appBar: selectedIndex == 1
            ? null
            : CustomAppBar(
                title: ListConstants.pageNames[selectedIndex],
                showBackButton: false,
                showWallet: true,
                leadingButton: IconButton(
                  onPressed: () async {
                    await launchUrlString('tel://${userProfilController.phoneNumber.value}');
                  },
                  icon: Icon(IconlyBold.call, color: ColorConstants.whiteColor),
                ),
              ),
        body: ListConstants.pages[selectedIndex],
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}
