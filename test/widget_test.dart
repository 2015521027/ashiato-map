import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keiken_memo/main.dart';

void main() {
  testWidgets('ホーム画面が表示される', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KeikenApp());
    await tester.pump();

    expect(find.text('足跡マップ'), findsOneWidget);
    expect(find.text('地図'), findsOneWidget);
    expect(find.text('一覧'), findsOneWidget);
  });
}
