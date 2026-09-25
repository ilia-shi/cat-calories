import 'package:cat_calories/features/calorie_tracking/ui/widgets/product_picker_sheet.dart';
import 'package:cat_calories_core/features/products/domain/product.dart';
import 'package:cat_calories_core/features/products/domain/product_repository_interface.dart';
import 'package:cat_calories_core/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyProductRepo implements ProductRepositoryInterface {
  @override
  Future<List<Product>> fetchRecentlyUsed(Profile profile,
          {int limit = 20}) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  const statusBar = 24.0;
  const keyboard = 350.0;

  final profile = Profile(
    id: '1',
    name: 'Me',
    wakingTimeSeconds: 0,
    caloriesLimitGoal: 2000,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: statusBar);
    tester.view.viewPadding = const FakeViewPadding(top: statusBar);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ProductPickerSheet.show(
              context,
              productsRepo: _EmptyProductRepo(),
              profile: profile,
            ),
            child: const Text('Add ingredient'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();
  }

  testWidgets('the search field stays below the status bar with the keyboard up',
      (tester) async {
    await openSheet(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(TextField)).top,
        greaterThanOrEqualTo(statusBar));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'still below the status bar when the device drops the top inset '
      'while the keyboard is up', (tester) async {
    await openSheet(tester);

    // What the screenshot showed: once the keyboard opens, the top inset
    // reads zero, so useSafeArea on its own no longer holds the sheet down.
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(BottomSheet)).top,
        greaterThanOrEqualTo(statusBar));
    expect(tester.takeException(), isNull);
  });

  testWidgets('takes 60% of the screen with the keyboard closed',
      (tester) async {
    await openSheet(tester);

    expect(tester.getRect(find.byType(BottomSheet)).height,
        moreOrLessEquals(800 * 0.6));
  });
}
