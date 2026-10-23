import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stams_frontend/models/enums.dart';
import 'package:stams_frontend/widgets/celebration.dart';
import 'package:stams_frontend/widgets/progress.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: child)));

void main() {
  testWidgets('ChecklistCard counts progress and offers only the next step', (tester) async {
    var tapped = '';
    await tester.pumpWidget(_app(ChecklistCard(
      title: 'Get set up',
      steps: [
        ChecklistStep(label: 'Add your first property', done: true, actionLabel: 'Add', onAction: () => tapped = 'property'),
        ChecklistStep(label: 'Add its rooms', done: false, hint: 'Bedrooms first', actionLabel: 'Add room', onAction: () => tapped = 'room'),
        ChecklistStep(label: 'Assign a student', done: false, actionLabel: 'Open', onAction: () => tapped = 'student'),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Bedrooms first'), findsOneWidget); // hint only for the next step
    expect(find.text('Add'), findsNothing); // finished step has no button
    expect(find.text('Open'), findsNothing); // later step waits its turn
    await tester.tap(find.text('Add room'));
    expect(tapped, 'room');
  });

  testWidgets('IssueProgress shows friendly stage names', (tester) async {
    await tester.pumpWidget(_app(const IssueProgress(status: IssueStatus.acknowledged, landlordFirstName: 'Tom', compact: true)));
    await tester.pumpAndSettle();
    expect(find.text('Seen · Tom has seen it'), findsOneWidget);

    await tester.pumpWidget(_app(const IssueProgress(status: IssueStatus.inProgress)));
    await tester.pumpAndSettle();
    for (final label in ['Reported', 'Seen', 'Fixing', 'Fixed']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('celebrate() shows the message and runs the next step', (tester) async {
    var next = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => celebrate(
                context,
                emoji: '🏠',
                title: 'Oak House is set up!',
                message: 'Next, add its rooms.',
                nextLabel: 'Add a room',
                onNext: () => next = true,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Oak House is set up!'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Add a room'));
    await tester.pumpAndSettle();
    expect(next, isTrue);
    expect(find.text('Oak House is set up!'), findsNothing); // dialog closed
  });
}
