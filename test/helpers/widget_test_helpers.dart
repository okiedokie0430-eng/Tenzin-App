import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget тестийн туслагч / Widget test helper
extension WidgetTesterExtension on WidgetTester {
  /// Riverpod provider-той widget pump хийх
  Future<void> pumpApp(
    Widget widget, {
    List<Override>? overrides,
    ThemeData? theme,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides ?? [],
        child: MaterialApp(
          theme: theme ?? ThemeData.light(),
          home: widget,
        ),
      ),
    );
  }

  /// Scaffold-той widget pump хийх
  Future<void> pumpScaffold(
    Widget widget, {
    List<Override>? overrides,
  }) async {
    await pumpApp(
      Scaffold(body: widget),
      overrides: overrides,
    );
  }

  /// Бүх анимацыг дуустал хүлээх
  Future<void> pumpUntilSettled({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    do {
      await pump();
    } while (DateTime.now().isBefore(deadline) && binding.hasScheduledFrame);
  }

  /// Текст олдохыг хүлээх
  Future<void> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await pump();
      if (find.text(text).evaluate().isNotEmpty) return;
      await pump(const Duration(milliseconds: 100));
    }

    throw Exception('Text "$text" not found within $timeout');
  }

  /// Widget-ийг олдохыг хүлээх
  Future<void> waitForWidget<T extends Widget>({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await pump();
      if (find.byType(T).evaluate().isNotEmpty) return;
      await pump(const Duration(milliseconds: 100));
    }

    throw Exception('Widget $T not found within $timeout');
  }
}

/// Finder туслагч / Finder helpers
extension FinderExtension on CommonFinders {
  /// Текст агуулсан widget олох
  Finder textContainingWidget(String text) {
    return find.byWidgetPredicate((widget) {
      if (widget is Text) {
        return widget.data?.contains(text) ?? false;
      }
      return false;
    });
  }

  /// Тодорхой key-тэй widget олох
  Finder byKeyString(String keyString) {
    return byKey(Key(keyString));
  }

  /// Descendant matcher
  Finder descendantOf(Finder ancestor, Finder descendant) {
    return find.descendant(of: ancestor, matching: descendant);
  }
}

/// Provider тестийн туслагч / Provider test helper
ProviderContainer createContainer({
  List<Override>? overrides,
  ProviderContainer? parent,
}) {
  final container = ProviderContainer(
    overrides: overrides ?? [],
    parent: parent,
  );

  // Auto-dispose after test
  addTearDown(container.dispose);

  return container;
}
