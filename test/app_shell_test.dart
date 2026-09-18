import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';

void main() {
  testWidgets('shell shows all navigation destinations', (tester) async {
    await tester.pumpWidget(const FreeCadLauncherApp());
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Profiles', 'Versions', 'Addons', 'Macros', 'Settings']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
