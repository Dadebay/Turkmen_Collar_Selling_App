import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:yaka2/core/icons/app_icon.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/core/widgets/profile_button.dart';

void main() {
  testWidgets(
    'profile icons use Hugeicons and the trailing circle stays tappable',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const AppIcon(IconlyLight.home),
                const AppIcon(Icons.usb_rounded),
                ProfilButton(
                  name: 'Profile',
                  icon: IconlyLight.profile,
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HugeIcon), findsNWidgets(3));
      expect(find.byIcon(Icons.usb_rounded), findsOneWidget);
      final circle = find.descendant(
        of: find.byType(ProfilButton),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(circle, findsOneWidget);

      await tester.tap(
        find.descendant(of: circle, matching: find.byType(AppIcon)),
      );
      expect(taps, 1);
    },
  );
}
