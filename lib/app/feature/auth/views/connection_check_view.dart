// ignore_for_file: file_names, always_use_package_imports

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kartal/kartal.dart';
import 'package:yaka2/app/feature/home/views/bottom_nav_bar_view.dart';
import 'package:yaka2/app/product/constants/icon_constants.dart';
import 'package:yaka2/app/product/sizes/widget_sizes.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

class ConnectionCheckpage extends StatefulWidget {
  const ConnectionCheckpage({super.key});

  @override
  _ConnectionCheckpageState createState() => _ConnectionCheckpageState();
}

class _ConnectionCheckpageState extends State<ConnectionCheckpage> {
  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  void checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 4), () {
          return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavBar()));
        });
      }
    } on SocketException catch (_) {
      DialogUtils.showNoConnectionDialog(onRetry: () {}, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: context.border.highBorderRadius,
                child: Image.asset(
                  IconConstants.logo,
                  width: WidgetSizes.size180.value,
                  height: WidgetSizes.size180.value,
                ),
              ),
            ),
          ),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
