import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/core/widgets/state_views.dart';

void main() {
  group('Kiểm thử Giao diện Widget (Widget Tests - Criteria 2 & 5)', () {
    testWidgets('18. LoadingView hiển thị thanh tiến trình và thông báo đang tải', (WidgetTester tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingView(
              message: 'Đang nạp 300 câu hỏi song ngữ...',
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang nạp 300 câu hỏi song ngữ...'), findsOneWidget);
      expect(find.text('Hủy bỏ'), findsOneWidget);

      await tester.tap(find.text('Hủy bỏ'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('19. ErrorViewWithRetry có lối ra rõ ràng: Nút Thử lại và Nút Quay lại', (WidgetTester tester) async {
      bool retried = false;
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorViewWithRetry(
              message: 'Kết nối mạng bị gián đoạn',
              onRetry: () => retried = true,
              onBack: () => backed = true,
            ),
          ),
        ),
      );

      expect(find.text('Có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Kết nối mạng bị gián đoạn'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(retried, isTrue);

      await tester.tap(find.text('Quay lại'));
      await tester.pump();
      expect(backed, isTrue);
    });

    testWidgets('20. EmptyStateView hiển thị đúng khi danh sách rỗng và có nút hành động', (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'Chưa có câu hỏi nào bị sai',
              message: 'Hãy tiếp tục làm thêm các bài thi thử.',
              actionLabel: 'Làm bài mới',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Chưa có câu hỏi nào bị sai'), findsOneWidget);
      expect(find.text('Hãy tiếp tục làm thêm các bài thi thử.'), findsOneWidget);
      expect(find.text('Làm bài mới'), findsOneWidget);

      await tester.tap(find.text('Làm bài mới'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });
  });
}
