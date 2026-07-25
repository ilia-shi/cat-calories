import 'package:cat_calories/common/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTopBar renders title, back button and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppTopBar(
                      title: 'Edit Profile',
                      actions: [
                        AppTopBarAction(icon: Icons.delete_outline, onPressed: () {}),
                        AppTopBarAction(
                          child: Transform.rotate(angle: 3.14, child: const Icon(Icons.sort)),
                          onPressed: () {},
                        ),
                        AppTopBarTextAction(label: 'Save', onPressed: () {}),
                      ],
                    ),
                    body: const SizedBox(),
                  ),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.sort), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppTopBar hides the back button on a root route', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: AppTopBar(title: 'Home'), body: SizedBox()),
      ),
    );

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('AppTopBarTextAction disables while busy', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: 'Add Sync Server',
            actions: [
              AppTopBarTextAction(
                label: 'Save',
                busyLabel: 'Saving...',
                busy: true,
                onPressed: () => taps++,
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.text('Saving...'), findsOneWidget);
    await tester.tap(find.text('Saving...'));
    await tester.pump();
    expect(taps, 0);
  });
}
