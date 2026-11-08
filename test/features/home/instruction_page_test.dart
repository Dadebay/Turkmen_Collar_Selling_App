import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/icons/app_icon.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:yaka2/core/l10n/app_translations.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/features/home/domain/entities/photo_entity.dart';
import 'package:yaka2/features/home/domain/entities/video_entity.dart';
import 'package:yaka2/features/home/domain/repositories/home_repository.dart';
import 'package:yaka2/features/home/presentation/pages/instruction_page.dart';
import 'package:yaka2/features/payment/data/datasources/payment_status_remote_data_source.dart';
import 'package:yaka2/features/payment/presentation/bloc/payment_status_bloc.dart';
import 'package:yaka2/injection_container.dart';

void main() {
  testWidgets('instruction cards and tabs fit a narrow Russian screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    AppTranslations.setLocale('ru');
    sl.registerSingleton<HomeRepository>(_GuideRepository());

    final paymentBloc = PaymentStatusBloc(
      remote: const PaymentStatusRemoteDataSource(
        baseUrl: 'https://example.com',
      ),
      storage: _TestStorage(),
    );
    addTearDown(() async {
      await paymentBloc.close();
      await sl.unregister<HomeRepository>();
      AppTranslations.setLocale('tk');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: BlocProvider.value(
          value: paymentBloc,
          child: const InstructionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пошаговые инструкции'), findsOneWidget);
    expect(find.text('Видео\nинструкции'), findsOneWidget);
    expect(find.text('Как войти в систему?'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppIcon && widget.icon == IconlyLight.arrowRightCircle,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Фото\nинструкции'));
    await tester.pumpAndSettle();
    expect(find.text('Фото\nинструкции'), findsOneWidget);
    expect(find.text('Пошаговые инструкции'), findsNothing);
    expect(find.text('Как перенести узоры на USB-накопитель?'), findsOneWidget);

    await tester.tap(find.text('Видео\nинструкции'));
    await tester.pumpAndSettle();
    expect(find.text('Пошаговые инструкции'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('video grid shows two columns and a working scroll hint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    AppTranslations.setLocale('ru');
    sl.registerSingleton<HomeRepository>(_GuideRepository());

    final paymentBloc = PaymentStatusBloc(
      remote: const PaymentStatusRemoteDataSource(
        baseUrl: 'https://example.com',
      ),
      storage: _TestStorage(),
    );
    addTearDown(() async {
      await paymentBloc.close();
      await sl.unregister<HomeRepository>();
      AppTranslations.setLocale('tk');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: BlocProvider.value(
          value: paymentBloc,
          child: const InstructionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text('Как войти в систему?').first);
    final second = tester.getTopLeft(
      find.text('Как пополнить свой баланс?').first,
    );
    expect((first.dy - second.dy).abs(), lessThan(1));
    expect(find.text('Листайте вниз'), findsOneWidget);

    final grid = tester.widget<GridView>(find.byType(GridView).first);
    final controller = grid.controller!;
    expect(controller.offset, 0);
    await tester.drag(find.byType(GridView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(find.text('Пошаговые инструкции'), findsNothing);

    await tester.drag(find.byType(GridView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('Пошаговые инструкции'), findsOneWidget);

    await tester.tap(find.text('Листайте вниз'));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo tab hides the intro and shows swipeable photos at top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    AppTranslations.setLocale('ru');
    sl.registerSingleton<HomeRepository>(_PhotoGuideRepository());

    final paymentBloc = PaymentStatusBloc(
      remote: const PaymentStatusRemoteDataSource(
        baseUrl: 'https://example.com',
      ),
      storage: _TestStorage(),
    );
    addTearDown(() async {
      await paymentBloc.close();
      await sl.unregister<HomeRepository>();
      AppTranslations.setLocale('tk');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: BlocProvider.value(
          value: paymentBloc,
          child: const InstructionPage(initialTab: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const carouselKey = ValueKey('instruction-photo-carousel-1');
    expect(find.text('Пошаговые инструкции'), findsNothing);
    expect(find.text('Как перенести узоры на USB-накопитель?'), findsOneWidget);
    expect(find.byKey(carouselKey), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(carouselKey)).dy, lessThan(260));
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Листайте вниз'), findsOneWidget);

    await tester.drag(find.byKey(carouselKey), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    final photoList = tester.widget<ListView>(
      find.byKey(const ValueKey('instruction-photo-list')),
    );
    expect(photoList.controller!.offset, 0);
    await tester.tap(find.text('Листайте вниз'));
    await tester.pumpAndSettle();
    expect(photoList.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

class _TestStorage extends LocalStorage {
  @override
  bool? get paymentDisabled => false;
}

class _GuideRepository implements HomeRepository {
  @override
  Future<Result<List<VideoEntity>>> getVideos() async => const Success([
    VideoEntity(name: 'videoTitle1', videoUrl: 'video.mp4'),
    VideoEntity(name: 'videoTitle2', videoUrl: 'video.mp4'),
    VideoEntity(name: 'videoTitle3', videoUrl: 'video.mp4'),
    VideoEntity(name: 'videoTitle4', videoUrl: 'video.mp4'),
    VideoEntity(name: 'videoTitle1', videoUrl: 'video.mp4'),
    VideoEntity(name: 'videoTitle2', videoUrl: 'video.mp4'),
  ]);

  @override
  Future<Result<List<PhotoEntity>>> getPhotos() async =>
      const Success([PhotoEntity(title: 'videoTitle4')]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PhotoGuideRepository extends _GuideRepository {
  @override
  Future<Result<List<PhotoEntity>>> getPhotos() async => const Success([
    PhotoEntity(
      title: 'videoTitle4',
      images: [
        'https://example.com/step-1.jpg',
        'https://example.com/step-2.jpg',
        'https://example.com/step-3.jpg',
      ],
    ),
    PhotoEntity(
      title: 'videoTitle2',
      images: ['https://example.com/step-4.jpg'],
    ),
    PhotoEntity(
      title: 'videoTitle3',
      images: ['https://example.com/step-5.jpg'],
    ),
  ]);
}
