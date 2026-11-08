import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/l10n/app_translations.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/features/user_profile/presentation/widgets/language_sheet.dart';

void main() {
  testWidgets('language sheet shows the current choice and returns a new one', (
    tester,
  ) async {
    AppTranslations.setLocale('tk');
    Future<String?>? choice;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  choice = showLanguageSheet(context, currentLocale: 'tk'),
              child: const Text('Open languages'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open languages'));
    await tester.pumpAndSettle();

    expect(find.text('Dil saýlaň'), findsOneWidget);
    expect(find.text('Türkmençe'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-option-ru')));
    await tester.pumpAndSettle();
    expect(await choice, 'ru');
  });
}
