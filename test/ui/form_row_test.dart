import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/ui/widgets/form_row.dart';

void main() {
  testWidgets('renders the label left of the field with a colon and 12 px gap', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: FormRow(
            icon: Icons.person_outline,
            label: 'Name',
            field: FormTextField(controller: controller),
          ),
        ),
      ),
    );

    expect(find.text('Name:'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    final labelRect = tester.getRect(find.text('Name:'));
    final fieldRect = tester.getRect(find.byType(TextField));
    expect(labelRect.right, lessThan(fieldRect.left));
    expect(fieldRect.left - labelRect.right, greaterThanOrEqualTo(12));

    final rowRect = tester.getRect(find.byType(FormRow));
    expect(rowRect.width, greaterThan(formLabelWidth));
  });

  testWidgets('FormDropdown shows the selected item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: FormRow(
            label: 'Build',
            field: FormDropdown<String>(
              value: 'a',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('A')),
                DropdownMenuItem(value: 'b', child: Text('B')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Build:'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });
}
