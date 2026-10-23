import 'package:flutter_test/flutter_test.dart';
import 'package:stams_frontend/models/app_notification.dart';
import 'package:stams_frontend/models/enums.dart';
import 'package:stams_frontend/models/issue.dart';
import 'package:stams_frontend/models/student_home.dart';

/// Shapes copied from the Spring backend's IssueResponse / NotificationResponse / MyRoomResponse.
void main() {
  test('Issue.fromJson reads an IssueResponse with its timeline and photo URLs', () {
    final issue = Issue.fromJson({
      'id': 7,
      'title': 'Tap dripping',
      'description': 'The kitchen tap drips all night long.',
      'status': 'IN_PROGRESS',
      'priority': 'HIGH',
      'roomId': 3,
      'roomName': 'Kitchen',
      'roomType': 'KITCHEN',
      'propertyId': 1,
      'propertyName': 'Oak House',
      'reporterId': 12,
      'reporterName': 'Aisha Bello',
      'landlordName': 'Tom Hadley',
      'photoUrls': ['/api/uploads/abc.png'],
      'nudgeCount': 1,
      'lastNudgedAt': '2026-10-23T08:00:00Z',
      'createdAt': '2026-10-22T08:00:00Z',
      'resolvedAt': null,
      'events': [
        {'id': 1, 'type': 'REPORTED', 'actorId': 12, 'actorName': 'Aisha Bello', 'status': 'REPORTED', 'createdAt': '2026-10-22T08:00:00Z'},
        {'id': 2, 'type': 'NUDGED', 'actorId': 12, 'actorName': 'Aisha Bello', 'nudgeNumber': 1, 'createdAt': '2026-10-23T08:00:00Z'},
      ],
    });
    expect(issue.status, IssueStatus.inProgress);
    expect(issue.roomType, RoomType.kitchen);
    expect(issue.events.map((e) => e.type), [IssueEventType.reported, IssueEventType.nudged]);
    expect(issue.events.last.nudgeNumber, 1);
    // Relative upload paths become full URLs so Image.network can load them.
    expect(issue.photos.single.url, endsWith('/api/uploads/abc.png'));
    expect(issue.photos.single.url, startsWith('http'));
  });

  test('AppNotification.fromJson reads the new NEW_ISSUE type', () {
    final n = AppNotification.fromJson({
      'id': 4,
      'type': 'NEW_ISSUE',
      'message': 'Aisha Bello reported “Tap dripping”',
      'read': false,
      'createdAt': '2026-10-22T08:00:00Z',
      'actorName': 'Aisha Bello',
      'issueId': 7,
      'issueTitle': 'Tap dripping',
      'roomName': 'Kitchen',
      'propertyName': 'Oak House',
    });
    expect(n.type, NotificationType.newIssue);
    expect(n.read, isFalse);
    expect(n.issueId, 7);
  });

  test('StudentHome.fromJson reads MyRoomResponse', () {
    final room = {
      'id': 2,
      'propertyId': 1,
      'propertyName': 'Oak House',
      'name': 'Room 1',
      'type': 'BEDROOM',
      'occupancyMode': 'SHARED',
      'capacity': 2,
      'occupied': 2,
      'openIssueCount': 0,
      'students': [],
    };
    final home = StudentHome.fromJson({
      'room': room,
      'propertyName': 'Oak House',
      'landlordName': 'Tom Hadley',
      'roommates': [
        {'id': 13, 'name': 'Chloe Nguyen', 'email': 'chloe@example.test'},
      ],
      'sharedSpaces': [
        {...room, 'id': 3, 'name': 'Kitchen', 'type': 'KITCHEN', 'occupancyMode': 'COMMUNAL', 'capacity': null, 'occupied': 0},
      ],
    });
    expect(home.landlordFirstName, 'Tom');
    expect(home.roommates.single.name, 'Chloe Nguyen');
    expect(home.sharedSpaces.single.isCommunal, isTrue);
  });
}
