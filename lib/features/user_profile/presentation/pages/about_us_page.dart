import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/profile_meta_remote_data_source.dart';
import '../../data/models/meta_models.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  late Future<Result<AboutUsModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ProfileMetaRemoteDataSource>().getAboutUs();
  }

  void _retry() {
    setState(() {
      _future = sl<ProfileMetaRemoteDataSource>().getAboutUs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.of(context).surface,
      appBar: const CustomAppBar(title: 'aboutUs', showBackButton: true),
      body: FutureBuilder<Result<AboutUsModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          final result = snapshot.data;
          if (result == null || result is Failure) {
            return ErrorState(onTap: _retry);
          }
          final about = result.dataOrThrow;
          if (about.body == null || about.body!.isEmpty) {
            return const EmptyState(
              name: 'emptyData',
              type: EmptyStateType.text,
            );
          }
          return Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'contactInformation'.tr,
                    style: TextStyle(
                      color: AppPalette.of(context).text,
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  about.body!,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppPalette.of(context).text,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
