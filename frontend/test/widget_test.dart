import 'package:flutter_test/flutter_test.dart';
import 'package:stams_frontend/data/api_client.dart';
import 'package:stams_frontend/data/demo/demo_repositories.dart';
import 'package:stams_frontend/data/demo/demo_store.dart';
import 'package:stams_frontend/models/enums.dart';
import 'package:stams_frontend/models/issue.dart';
import 'package:stams_frontend/models/user.dart';
import 'package:stams_frontend/utils/format.dart';

void main() {
  group('enum JSON', () {
    test('maps SCREAMING_SNAKE_CASE to camelCase and back', () {
      expect(enumFromJson(IssueStatus.values, 'IN_PROGRESS'), IssueStatus.inProgress);
      expect(enumFromJson(RoomType.values, 'COMMON_AREA'), RoomType.commonArea);
      expect(enumFromJson(Placement.values, 'NOT_IN_A_ROOM'), Placement.notInARoom);
      expect(enumToJson(IssueStatus.inProgress), 'IN_PROGRESS');
      expect(enumToJson(OccupancyMode.communal), 'COMMUNAL');
    });
  });

  group('IssueFilter', () {
    final store = DemoStore();
    final all = store.issues.values.toList();

    test('default shows only open issues, most nudged first', () {
      final result = const IssueFilter().apply(all);
      expect(result.every((i) => i.isOpen), isTrue);
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].nudgeCount, greaterThanOrEqualTo(result[i].nudgeCount));
      }
      expect(result.first.title, startsWith('Bed frame slats'));
    });

    test('narrows by status, priority and property', () {
      final high = const IssueFilter(priorities: {IssuePriority.high}).apply(all);
      expect(high, isNotEmpty);
      expect(high.every((i) => i.priority == IssuePriority.high), isTrue);

      final resolved = const IssueFilter(status: IssueStatus.resolved).apply(all);
      expect(resolved.every((i) => i.status == IssueStatus.resolved), isTrue);

      expect(const IssueFilter(propertyId: 103).apply(all), isEmpty); // Elm Terrace has no issues
    });

    test('oldest first sorts by report date', () {
      final result = const IssueFilter(sort: IssueSort.oldest).apply(all);
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].createdAt.isAfter(result[i].createdAt), isFalse);
      }
    });
  });

  group('nudge rules', () {
    test('a student can nudge once per 24 hours, and the landlord is alerted', () async {
      final store = DemoStore();
      final repo = DemoIssueRepository(store);
      final alertsBefore = store.notifications.values.where((n) => n.recipientId == demoLandlordId).length;

      // Aisha's bed issue was last nudged 26h ago, so a nudge is allowed.
      final nudged = await repo.nudge(300, studentId: demoStudentId);
      expect(nudged.nudgeCount, 5);
      expect(nudged.nextNudgeAt(DateTime.now()), isNotNull);
      expect(store.notifications.values.where((n) => n.recipientId == demoLandlordId).length, alertsBefore + 1);

      // Straight away again: refused.
      expect(repo.nudge(300, studentId: demoStudentId), throwsA(isA<ApiException>()));
    });

    test('resolved issues cannot be nudged', () async {
      final repo = DemoIssueRepository(DemoStore());
      expect(repo.nudge(311, studentId: demoStudentId), throwsA(isA<ApiException>()));
    });

    test('status only moves forward and the student is notified', () async {
      final store = DemoStore();
      final repo = DemoIssueRepository(store);
      final updated = await repo.update(
        300,
        const IssueUpdate(status: IssueStatus.resolved, priority: IssuePriority.high, note: 'All sorted'),
        landlordId: demoLandlordId,
      );
      expect(updated.status, IssueStatus.resolved);
      expect(updated.resolvedAt, isNotNull);
      expect(store.notifications.values.any((n) => n.recipientId == demoStudentId && n.notification.status == IssueStatus.resolved), isTrue);

      expect(
        repo.update(300, const IssueUpdate(status: IssueStatus.acknowledged, priority: IssuePriority.high), landlordId: demoLandlordId),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('Fmt', () {
    final now = DateTime(2026, 9, 30, 12);

    test('relative times match the design copy', () {
      expect(Fmt.ago(now.subtract(const Duration(hours: 2)), now: now), '2h ago');
      expect(Fmt.ago(now.subtract(const Duration(days: 1)), now: now), 'yesterday');
      expect(Fmt.age(now.subtract(const Duration(days: 6)), now: now), '6 days ago');
      expect(Fmt.stamp(DateTime(2026, 9, 30, 7, 48), now: now), 'Today, 07:48');
      expect(Fmt.stamp(DateTime(2026, 9, 24, 21, 40), now: now), 'Thu 24 Sep, 21:40');
    });

    test('countdown, ordinals, plurals', () {
      expect(Fmt.countdown(const Duration(hours: 21, minutes: 48)), '21h 48m');
      expect(Fmt.countdown(const Duration(minutes: 12)), '12m');
      expect([1, 2, 3, 4, 11, 22].map(Fmt.ordinal), ['1st', '2nd', '3rd', '4th', '11th', '22nd']);
      expect(Fmt.plural(1, 'nudge'), '1 nudge');
      expect(Fmt.plural(4, 'nudge'), '4 nudges');
    });
  });
}
