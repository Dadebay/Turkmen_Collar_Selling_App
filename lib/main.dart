import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/feature/auth/views/connection_check_view.dart';
import 'package:yaka2/app/product/constants/string_constants.dart';
import 'package:yaka2/app/product/constants/theme_contants.dart';
import 'package:yaka2/app/product/initialize/app_start_init.dart';
import 'package:yaka2/app/product/initialize/notification_service.dart';

import 'app/product/utils/translations.dart';

Future<void> main() async {
  await AppStartInit.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = GetStorage();
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      FCMConfig().sendNotification(body: message.notification!.body!, title: message.notification!.title!);
    });
    AppStartInit.getNotification();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: StringConstants.appName,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
      useInheritedMediaQuery: true,
      theme: AppThemes.lightTheme,
      fallbackLocale: const Locale('tr'),
      locale: storage.read('langCode') != null ? Locale(storage.read('langCode')) : const Locale('tr'),
      translations: MyTranslations(),
      defaultTransition: Transition.fade,
      home: const ConnectionCheckpage(),
    );
  }
}
