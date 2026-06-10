import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clipq/main.dart';
import 'package:clipq/app_router.dart';
import 'package:clipq/features/clipboard/application/clipboard_sync_service.dart';

class FakeClipboardSyncService extends ClipboardSyncService {
  @override
  Future<SyncStatus> build() async {
    return SyncStatus.idle;
  }
}

void main() {
  testWidgets('ClipQ smoke test', (WidgetTester tester) async {
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clipboardSyncServiceProvider.overrideWith(() => FakeClipboardSyncService()),
          routerProvider.overrideWithValue(testRouter),
        ],
        child: const ClipQApp(),
      ),
    );

    expect(find.byType(ClipQApp), findsOneWidget);
  });
}
