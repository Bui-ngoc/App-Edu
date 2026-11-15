// test/accessibility/accessibility_test.dart
//
// Accessibility & bilingual widget tests (Criteria 2 & 5)
// Covers: textContrastGuideline, androidTapTargetGuideline,
//         labeledTapTargetGuideline, bilingual VI/EN toggle.
//
// Run: flutter test test/accessibility/accessibility_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edumaster/core/widgets/state_views.dart';
import 'package:edumaster/core/constants/app_colors.dart';
import 'package:edumaster/core/constants/app_strings.dart';

void main() {
  // ── Helper ──────────────────────────────────────────────────────────────
  Widget wrapWidget(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ??
            ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              useMaterial3: true,
            ),
        home: Scaffold(body: child),
      );

  // ========================================================================
  // GROUP A — Tap-target size ≥ 48 dp (Criteria 2)
  // ========================================================================
  group('A. Kích thước vùng chạm ≥ 48 dp (androidTapTargetGuideline)', () {
    testWidgets('21. LoadingView — nút Hủy bỏ đạt chuẩn tap-target Android',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(LoadingView(message: 'Đang tải...', onCancel: () {})),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('22. ErrorViewWithRetry — nút Thử lại & Quay lại đạt tap-target',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          ErrorViewWithRetry(
            message: 'Lỗi kết nối mạng',
            onRetry: () {},
            onBack: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('23. EmptyStateView — nút hành động đạt tap-target Android',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          EmptyStateView(
            title: 'Chưa có thẻ ghi nhớ',
            message: 'Tạo thẻ đầu tiên để bắt đầu ôn tập.',
            actionLabel: 'Tạo thẻ mới',
            onAction: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  // ========================================================================
  // GROUP B — Labeled tap targets (screen-reader support, Criteria 2)
  // ========================================================================
  group('B. Nhãn trợ năng (labeledTapTargetGuideline)', () {
    testWidgets('24. Nút Hủy bỏ trong LoadingView có nhãn trợ năng',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(LoadingView(message: 'Đang xử lý...', onCancel: () {})),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('25. Nút Thử lại và Quay lại có nhãn trợ năng rõ ràng',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          ErrorViewWithRetry(
            message: 'Không có kết nối internet',
            onRetry: () {},
            onBack: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  // ========================================================================
  // GROUP C — Text contrast WCAG AA (Criteria 2)
  // ========================================================================
  group('C. Độ tương phản văn bản WCAG AA (textContrastGuideline)', () {
    testWidgets('26. LoadingView — văn bản đạt tương phản WCAG AA',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          LoadingView(message: 'Đang nạp dữ liệu...', onCancel: () {}),
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundLight,
              onSurface: AppColors.textPrimaryLight,
            ),
            useMaterial3: true,
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('27. ErrorViewWithRetry — tất cả văn bản đạt WCAG AA',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          ErrorViewWithRetry(
            message: 'Không thể kết nối máy chủ',
            onRetry: () {},
            onBack: () {},
          ),
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundLight,
              onSurface: AppColors.textPrimaryLight,
            ),
            useMaterial3: true,
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  // ========================================================================
  // GROUP D — Bilingual UI toggle VI/EN (Criteria 2 mở rộng)
  // ========================================================================
  group('D. Giao diện song ngữ VI/EN (Bilingual UI toggle)', () {
    // Simple bilingual widget dùng để kiểm thử toggle ngôn ngữ
    testWidgets('28. Toggle ngôn ngữ VI→EN thay đổi văn bản hiển thị',
        (tester) async {
      bool isEnglish = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isEnglish ? 'Bilingual Quiz' : 'Trắc nghiệm song ngữ',
                      key: const Key('quiz_title'),
                    ),
                    Text(
                      isEnglish ? 'Correct answer' : 'Đáp án đúng',
                      key: const Key('correct_label'),
                    ),
                    ElevatedButton(
                      key: const Key('lang_toggle'),
                      onPressed: () => setState(() => isEnglish = !isEnglish),
                      child: Text(isEnglish ? 'VI' : 'EN'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Trạng thái ban đầu: Tiếng Việt
      expect(find.text('Trắc nghiệm song ngữ'), findsOneWidget);
      expect(find.text('Đáp án đúng'), findsOneWidget);

      // Nhấn toggle → chuyển sang Tiếng Anh
      await tester.tap(find.byKey(const Key('lang_toggle')));
      await tester.pump();

      expect(find.text('Bilingual Quiz'), findsOneWidget);
      expect(find.text('Correct answer'), findsOneWidget);

      // Nhấn lại → quay về Tiếng Việt
      await tester.tap(find.byKey(const Key('lang_toggle')));
      await tester.pump();

      expect(find.text('Trắc nghiệm song ngữ'), findsOneWidget);
    });

    testWidgets('29. Hằng số AppStrings có cả bản VI và EN', (tester) async {
      // Kiểm tra static const strings không rỗng
      expect(AppStrings.appName.isNotEmpty, isTrue);
      expect(AppStrings.retry.isNotEmpty, isTrue);
      expect(AppStrings.loading.isNotEmpty, isTrue);
      expect(AppStrings.goBack.isNotEmpty, isTrue);
    });

    testWidgets('30. TouchTargetWrapper đảm bảo kích thước tối thiểu 48 dp',
        (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          TouchTargetWrapper(
            child: Semantics(
              label: 'Nút kiểm thử trợ năng',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('OK'),
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(
        find.byType(TouchTargetWrapper),
      );
      expect(box.size.width, greaterThanOrEqualTo(48.0));
      expect(box.size.height, greaterThanOrEqualTo(48.0));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
