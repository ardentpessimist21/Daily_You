import 'package:daily_you/config_provider.dart';
import 'package:daily_you/fork/quick_entry/quick_entry_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Settings › Quick entry opens without errors', (tester) async {
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    await tester.pumpWidget(ChangeNotifierProvider<ConfigProvider>.value(
      value: ConfigProvider.instance,
      child: const MaterialApp(home: QuickEntrySettings()),
    ));
    await tester.pump();
    // 3.7.0.51 showed a black page: the switch got a null value
    expect(errors.map((e) => e.exceptionAsString()), isEmpty);
  });
}
