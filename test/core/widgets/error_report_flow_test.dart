import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/l10n/app_translations.dart';
import 'package:yaka2/core/services/error_report_screenshot.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/core/theme/color_constants.dart';
import 'package:yaka2/core/widgets/custom_widgets.dart';
import 'package:yaka2/core/widgets/error_report_dialog.dart';

void main() {
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('yaka-report-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return temporaryDirectory.path;
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    await temporaryDirectory.delete(recursive: true);
  });

  test('technical failures can be reported; offline and validation cannot', () {
    expect(
      shouldOfferErrorReport(
        'downloadFailedTitle',
        'HandshakeException: Connection terminated during handshake',
        ColorConstants.redColor,
      ),
      isTrue,
    );
    expect(
      shouldOfferErrorReport(
        'downloadFailedTitle',
        'downloadFailedNetwork',
        ColorConstants.redColor,
      ),
      isFalse,
    );
    expect(
      shouldOfferErrorReport(
        'noConnection3',
        'errorEmpty',
        ColorConstants.redColor,
      ),
      isFalse,
    );
  });

  testWidgets('report button opens screenshot preview before sending', (
    tester,
  ) async {
    AppTranslations.setLocale('tk');
    late BuildContext pageContext;
    await tester.pumpWidget(
      RepaintBoundary(
        key: ErrorReportScreenshot.boundaryKey,
        child: MaterialApp(
          theme: AppThemes.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return const Text('Visible page');
              },
            ),
          ),
        ),
      ),
    );

    showSnackBar(
      pageContext,
      'downloadFailedTitle',
      'HandshakeException: Connection terminated during handshake',
      ColorConstants.redColor,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ýalňyşlygy iber'), findsOneWidget);

    await tester.tap(find.text('Ýalňyşlygy iber'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorReportDialog), findsOneWidget);
    expect(find.text('Ekran suraty'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
