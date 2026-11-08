import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/theme/theme_reveal.dart';

void main() {
  testWidgets('reveals dark from the left and light from the right', (
    tester,
  ) async {
    final key = GlobalKey<ThemeRevealState>();
    late StateSetter update;
    var dark = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            themeAnimationDuration: Duration.zero,
            home: ThemeReveal(
              key: key,
              child: Center(child: Text(dark ? 'Dark screen' : 'Light screen')),
            ),
          );
        },
      ),
    );
    await tester.pump();

    final darkTransition = key.currentState!.run(
      () => update(() => dark = true),
      direction: ThemeRevealDirection.leftToRight,
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.text('Dark screen'), findsOneWidget);
    final wipe = find.byKey(const ValueKey('theme-reveal-wipe'));
    expect(wipe, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 325));
    final darkClip = tester
        .widget<ClipRect>(wipe)
        .clipper!
        .getClip(const Size(800, 600));
    expect(darkClip.left, greaterThan(0));
    expect(darkClip.left, lessThan(800));
    expect(darkClip.right, 800);

    await tester.pumpAndSettle();
    await darkTransition;
    expect(wipe, findsNothing);

    final lightTransition = key.currentState!.run(
      () => update(() => dark = false),
      direction: ThemeRevealDirection.rightToLeft,
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.text('Light screen'), findsOneWidget);
    expect(wipe, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 325));
    final lightClip = tester
        .widget<ClipRect>(wipe)
        .clipper!
        .getClip(const Size(800, 600));
    expect(lightClip.left, 0);
    expect(lightClip.right, greaterThan(0));
    expect(lightClip.right, lessThan(800));

    await tester.pumpAndSettle();
    await lightTransition;
    expect(wipe, findsNothing);
  });
}
