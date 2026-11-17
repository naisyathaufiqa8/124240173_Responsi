import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_hub/widgets/wishlist_swipe_item.dart';

void main() {
  testWidgets('vertical trackpad scroll does not dismiss the item', (
    tester,
  ) async {
    var dismissCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WishlistSwipeItem(
            onDismiss: () async {
              dismissCount++;
              return true;
            },
            child: const SizedBox(
              height: 100,
              child: ColoredBox(color: Colors.white, child: Text('Product')),
            ),
          ),
        ),
      ),
    );

    final position = tester.getCenter(find.text('Product'));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.trackpad,
        position: position,
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump();

    expect(dismissCount, 0);
    expect(find.text('Product'), findsOneWidget);
  });

  testWidgets('horizontal trackpad scroll accumulates to dismiss threshold', (
    tester,
  ) async {
    var dismissCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WishlistSwipeItem(
            onDismiss: () async {
              dismissCount++;
              return true;
            },
            child: const SizedBox(
              height: 100,
              child: ColoredBox(color: Colors.white, child: Text('Product')),
            ),
          ),
        ),
      ),
    );

    final position = tester.getCenter(find.text('Product'));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.trackpad,
        position: position,
        scrollDelta: const Offset(-50, 0),
      ),
    );
    await tester.pump();
    expect(dismissCount, 0);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        kind: PointerDeviceKind.trackpad,
        position: position,
        scrollDelta: const Offset(-45, 0),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(dismissCount, 1);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('trackpad pan-zoom update dismisses the item once', (
    tester,
  ) async {
    var dismissCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WishlistSwipeItem(
            onDismiss: () async {
              dismissCount++;
              return true;
            },
            child: const SizedBox(
              height: 100,
              child: ColoredBox(color: Colors.white, child: Text('Product')),
            ),
          ),
        ),
      ),
    );

    final position = tester.getCenter(find.text('Product'));
    await tester.sendEventToBinding(
      PointerPanZoomStartEvent(pointer: 1, position: position),
    );
    await tester.sendEventToBinding(
      PointerPanZoomUpdateEvent(
        pointer: 1,
        position: position,
        pan: const Offset(-100, 0),
        panDelta: const Offset(-100, 0),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendEventToBinding(
      PointerPanZoomEndEvent(pointer: 1, position: position),
    );
    await tester.pumpAndSettle();

    expect(dismissCount, 1);
  });

  testWidgets('mouse drag supports dismissing the item', (tester) async {
    var dismissCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WishlistSwipeItem(
            onDismiss: () async {
              dismissCount++;
              return true;
            },
            child: const SizedBox(
              height: 100,
              child: ColoredBox(color: Colors.white, child: Text('Product')),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Product')),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(dismissCount, 1);
  });
}
