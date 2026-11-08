import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/result/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/profile_meta_remote_data_source.dart';
import '../../data/models/meta_models.dart';
import '../../../../core/icons/app_icon.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  late Future<Result<List<FAQModel>>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<ProfileMetaRemoteDataSource>().getFaq();
  }

  void _retry() {
    setState(() {
      _future = sl<ProfileMetaRemoteDataSource>().getFaq();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'questions', showBackButton: true),
      body: FutureBuilder<Result<List<FAQModel>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          final result = snapshot.data;
          if (result == null || result is Failure) {
            return ErrorState(onTap: _retry);
          }
          final faqs = result.dataOrThrow;
          if (faqs.isEmpty) {
            return const EmptyState(name: 'empty', type: EmptyStateType.text);
          }
          return ListView.builder(
            itemCount: faqs.length,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final faq = faqs[index];
              final title = Text(
                faq.title ?? '',
                style: TextStyle(
                  color: AppPalette.of(context).text,
                  fontSize: 18,
                ),
              );

              // Image FAQs open the gallery directly instead of expanding.
              if (faq.images.isNotEmpty) {
                return ListTile(
                  title: title,
                  trailing: AppIcon(
                    Icons.image_outlined,
                    color: AppPalette.of(context).text,
                  ),
                  onTap: () => context.push(
                    AppRoutes.photoGallery,
                    extra: {'images': faq.images, 'title': faq.title},
                  ),
                );
              }

              return ExpansionTile(
                title: title,
                collapsedIconColor: AppPalette.of(context).text,
                iconColor: AppPalette.of(context).text,
                childrenPadding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 0,
                  bottom: 12,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.body ?? '',
                      style: TextStyle(
                        color: AppPalette.of(context).text,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
