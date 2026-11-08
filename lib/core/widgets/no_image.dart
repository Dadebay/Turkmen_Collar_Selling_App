import 'package:flutter/material.dart';

import '../l10n/app_translations.dart';

class NoImage extends StatelessWidget {
  const NoImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('noImage'.tr));
  }
}
