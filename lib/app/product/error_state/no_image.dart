import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

class NoImage extends StatelessWidget {
  const NoImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('noImage'.tr));
  }
}
