import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:table_tales/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('TableTales app renders main screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TableTalesApp());
    await tester.pumpAndSettle();

    expect(find.text('TableTales'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Our Story'), findsWidgets);
  });
}
