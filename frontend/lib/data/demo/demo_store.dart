import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../models/property.dart';
import '../../models/user.dart';

/// Password for every seeded demo account (see frontend/README.md).
const demoPassword = 'stams-demo';

/// Seeded ids the hybrid mode "acts as" for features the backend doesn't have yet.
const demoLandlordId = 1;
const demoStudentId = 10;

class DemoUser {
  DemoUser({required this.id, required this.name, required this.email, required this.role, this.password = demoPassword, this.roomId});

  final int id;
  final String name;
  final String email;
  final Role role;
  final String password;
  int? roomId;

  AppUser toAppUser() => AppUser(id: id, name: name, email: email, role: role);
  StudentSummary toSummary() => StudentSummary(id: id, name: name, email: email);
}

class DemoProperty {
  DemoProperty({required this.id, required this.landlordId, required this.input, required this.createdAt});

  final int id;
  final int landlordId;
  PropertyInput input;
  final DateTime createdAt;
}

class DemoRoom {
  DemoRoom({required this.id, required this.propertyId, required this.input});

  final int id;
  final int propertyId;
  RoomInput input;
}

class DemoNotification {
  DemoNotification({required this.recipientId, required this.notification});

  final int recipientId;
  AppNotification notification;
}

/// In-memory database behind every demo repository. Lives for the app session.
class DemoStore {
  DemoStore() {
    _seed();
  }

  final users = <int, DemoUser>{};
  final properties = <int, DemoProperty>{};
  final rooms = <int, DemoRoom>{};
  final issues = <int, Issue>{};
  final notifications = <int, DemoNotification>{};

  /// Demo mode's signed-in user.
  int? signedInUserId;

  int _nextId = 1000;
  int nextId() => _nextId++;

  // ---- Views -------------------------------------------------------------

  List<DemoUser> studentsIn(int roomId) => users.values.where((u) => u.roomId == roomId).toList();

  int openIssuesIn(int roomId) => issues.values.where((i) => i.roomId == roomId && i.isOpen).length;

  Room roomView(int id) {
    final r = rooms[id]!;
    final p = properties[r.propertyId]!;
    final students = studentsIn(id);
    return Room(
      id: r.id,
      propertyId: p.id,
      propertyName: p.input.name,
      name: r.input.name,
      type: r.input.type,
      occupancyMode: r.input.occupancyMode,
      capacity: r.input.effectiveCapacity,
      occupied: students.length,
      openIssueCount: openIssuesIn(id),
      students: students.map((s) => s.toSummary()).toList(),
    );
  }

  Property propertyView(int id, {bool withRooms = false}) {
    final p = properties[id]!;
    final roomViews = rooms.values.where((r) => r.propertyId == id).map((r) => roomView(r.id)).toList();
    final open = issues.values.where((i) => i.propertyId == id && i.isOpen);
    return Property(
      id: p.id,
      name: p.input.name,
      addressLine1: p.input.addressLine1,
      addressLine2: p.input.addressLine2,
      city: p.input.city,
      postalCode: p.input.postalCode,
      createdAt: p.createdAt,
      roomCount: roomViews.length,
      bedsFilled: roomViews.where((r) => !r.isCommunal).fold(0, (n, r) => n + r.occupied),
      bedsTotal: roomViews.where((r) => !r.isCommunal).fold(0, (n, r) => n + (r.capacity ?? 0)),
      openIssueCount: open.length,
      openIssueNudges: open.fold(0, (n, i) => n + i.nudgeCount),
      rooms: withRooms ? roomViews : null,
    );
  }

  int landlordOfRoom(int roomId) => properties[rooms[roomId]!.propertyId]!.landlordId;

  void notify(int recipientId, AppNotification Function(int id) build) {
    final id = nextId();
    notifications[id] = DemoNotification(recipientId: recipientId, notification: build(id));
  }

  // ---- Seed --------------------------------------------------------------

  void _seed() {
    final now = DateTime.now();
    DateTime ago({int days = 0, int hours = 0, int minutes = 0}) => now.subtract(Duration(days: days, hours: hours, minutes: minutes));

    void user(int id, String name, String email, Role role) =>
        users[id] = DemoUser(id: id, name: name, email: email, role: role);

    user(1, 'Tom Hadley', 'tom.hadley@hadleylets.co.uk', Role.landlord);
    user(10, 'Aisha Bello', 'aisha.bello@uni.ac.uk', Role.student);
    user(11, 'Chloe Nguyen', 'chloe.nguyen@uni.ac.uk', Role.student);
    user(12, 'Liam Chen', 'liam.chen@uni.ac.uk', Role.student);
    user(13, 'Ben Adeyemi', 'ben.adeyemi@uni.ac.uk', Role.student);
    user(14, 'Kwame Mensah', 'kwame.mensah@uni.ac.uk', Role.student);
    user(15, 'Sofia Marín', 'sofia.marin@uni.ac.uk', Role.student);
    user(16, 'Ravi Patel', 'ravi.patel@uni.ac.uk', Role.student);
    user(17, 'Maya Thomas', 'maya.thomas@uni.ac.uk', Role.student);
    user(18, 'Maya Tran', 'maya.tran@leedsmet.ac.uk', Role.student);
    user(19, 'Grace Kim', 'grace.kim@uni.ac.uk', Role.student);
    user(20, 'Leo Rossi', 'leo.rossi@uni.ac.uk', Role.student);
    user(21, 'Priya Shah', 'priya.shah@uni.ac.uk', Role.student);
    user(22, 'Omar Farouk', 'omar.farouk@uni.ac.uk', Role.student);
    user(23, 'Hannah Okafor', 'hannah.okafor@uni.ac.uk', Role.student);
    user(24, 'Jack Wilson', 'jack.wilson@uni.ac.uk', Role.student);

    void property(int id, String name, String line1, String city, String postcode, {String? line2}) => properties[id] = DemoProperty(
          id: id,
          landlordId: 1,
          createdAt: ago(days: 400),
          input: PropertyInput(name: name, addressLine1: line1, addressLine2: line2, city: city, postalCode: postcode),
        );

    property(100, 'Parkview Student Residence', '14 Parkview Road', 'Leeds', 'LS6 2QT', line2: 'Headingley');
    property(101, 'The Mill House', '48 Canal Wharf', 'Leeds', 'LS11 5PS');
    property(102, 'Hollis Court', '3 Hollis Street', 'Leeds', 'LS2 9JT');
    property(103, 'Elm Terrace', '22 Elm Terrace', 'Leeds', 'LS4 2BB');

    void room(int id, int propertyId, String name, RoomType type, OccupancyMode mode, {int? capacity, List<int> students = const []}) {
      rooms[id] = DemoRoom(
        id: id,
        propertyId: propertyId,
        input: RoomInput(name: name, type: type, occupancyMode: mode, capacity: capacity),
      );
      for (final s in students) {
        users[s]!.roomId = id;
      }
    }

    // Parkview
    room(200, 100, 'Room 1', RoomType.bedroom, OccupancyMode.single, students: [12]);
    room(201, 100, 'Room 2', RoomType.bedroom, OccupancyMode.shared, capacity: 2, students: [10, 11]);
    room(202, 100, 'Room 3', RoomType.bedroom, OccupancyMode.shared, capacity: 2, students: [13]);
    room(203, 100, 'Room 4', RoomType.bedroom, OccupancyMode.single, students: [21]);
    room(204, 100, 'Room 5', RoomType.bedroom, OccupancyMode.single, students: [22]);
    room(205, 100, 'Room 6', RoomType.bedroom, OccupancyMode.shared, capacity: 2, students: [19, 20]);
    room(206, 100, 'Kitchen', RoomType.kitchen, OccupancyMode.communal);
    room(207, 100, 'Bathroom A', RoomType.bathroom, OccupancyMode.communal);
    room(208, 100, 'Bathroom B', RoomType.bathroom, OccupancyMode.communal);
    room(209, 100, 'Lounge', RoomType.commonArea, OccupancyMode.communal);
    // The Mill House
    room(210, 101, 'Room 1', RoomType.bedroom, OccupancyMode.single, students: [23]);
    room(211, 101, 'Room 3', RoomType.bedroom, OccupancyMode.shared, capacity: 2, students: [24]);
    room(212, 101, 'Room 5', RoomType.bedroom, OccupancyMode.single, students: [14]);
    room(213, 101, 'Kitchen', RoomType.kitchen, OccupancyMode.communal);
    room(214, 101, 'Entrance hall', RoomType.commonArea, OccupancyMode.communal);
    // Hollis Court
    room(220, 102, 'Room 2', RoomType.bedroom, OccupancyMode.single, students: [15]);
    room(221, 102, 'Room 3', RoomType.bedroom, OccupancyMode.single, students: [16]);
    room(222, 102, 'Room 4', RoomType.bedroom, OccupancyMode.single, students: [18]);
    room(223, 102, 'Kitchen', RoomType.kitchen, OccupancyMode.communal);
    room(224, 102, 'Bathroom B', RoomType.bathroom, OccupancyMode.communal);
    room(225, 102, 'Common area', RoomType.commonArea, OccupancyMode.communal);
    // Elm Terrace
    room(230, 103, 'Room 1', RoomType.bedroom, OccupancyMode.shared, capacity: 2);
    room(231, 103, 'Room 2', RoomType.bedroom, OccupancyMode.single);
    room(232, 103, 'Kitchen', RoomType.kitchen, OccupancyMode.communal);

    // Issues. Each step is (type, time, actor, status/priority/note).
    void issue(
      int id, {
      required int roomId,
      required int reporterId,
      required String title,
      required String description,
      required IssuePriority priority,
      required List<_Step> steps,
      List<IssuePhoto> photos = const [],
    }) {
      final r = rooms[roomId]!;
      final p = properties[r.propertyId]!;
      final landlord = users[p.landlordId]!;
      final reporter = users[reporterId]!;
      var status = IssueStatus.reported;
      var nudges = 0;
      DateTime? lastNudged;
      DateTime? resolvedAt;
      final events = <IssueEvent>[];
      for (final s in steps) {
        final actor = s.type == IssueEventType.reported || s.type == IssueEventType.nudged ? reporter : landlord;
        if (s.status != null) status = s.status!;
        if (s.type == IssueEventType.nudged) {
          nudges++;
          lastNudged = s.at;
        }
        if (s.status == IssueStatus.resolved) resolvedAt = s.at;
        events.add(IssueEvent(
          id: nextId(),
          type: s.type,
          actorId: actor.id,
          actorName: actor.name,
          createdAt: s.at,
          status: s.status,
          note: s.note,
          nudgeNumber: s.type == IssueEventType.nudged ? nudges : null,
        ));
        // Mirror the backend: nudges alert the landlord, status changes alert the student.
        final unread = now.difference(s.at) < const Duration(hours: 24);
        if (s.type == IssueEventType.nudged) {
          final n = nudges;
          notify(landlord.id, (nid) => AppNotification(
                id: nid,
                type: NotificationType.nudge,
                message: '${reporter.name} nudged you',
                createdAt: s.at,
                read: !unread,
                actorName: reporter.name,
                issueId: id,
                issueTitle: title,
                roomName: r.input.name,
                propertyName: p.input.name,
                nudgeNumber: n,
              ));
        } else if (s.type == IssueEventType.statusChanged) {
          notify(reporter.id, (nid) => AppNotification(
                id: nid,
                type: NotificationType.statusChange,
                message: '${landlord.name} moved your issue to ${s.status!.label}',
                createdAt: s.at,
                read: !unread,
                actorName: landlord.name,
                issueId: id,
                issueTitle: title,
                roomName: r.input.name,
                propertyName: p.input.name,
                status: s.status,
              ));
        }
      }
      issues[id] = Issue(
        id: id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        roomId: roomId,
        roomName: r.input.name,
        roomType: r.input.type,
        propertyId: p.id,
        propertyName: p.input.name,
        reporterId: reporterId,
        reporterName: reporter.name,
        landlordName: landlord.name,
        createdAt: steps.first.at,
        photos: photos,
        nudgeCount: nudges,
        lastNudgedAt: lastNudged,
        resolvedAt: resolvedAt,
        events: events,
      );
    }

    const reported = IssueEventType.reported;
    const changed = IssueEventType.statusChanged;
    const nudged = IssueEventType.nudged;

    issue(300,
        roomId: 201,
        reporterId: 10,
        title: 'Bed frame slats snapped — mattress sagging',
        description: 'Two slats under the mattress snapped on Thursday night and the mattress now dips in the middle. '
            'I’ve been sleeping on the floor since.',
        priority: IssuePriority.high,
        photos: const [IssuePhoto.placeholder('broken bed slats'), IssuePhoto.placeholder('mattress dip')],
        steps: [
          _Step(reported, ago(days: 6, hours: 2), status: IssueStatus.reported),
          _Step(changed, ago(days: 5, hours: 14), status: IssueStatus.acknowledged),
          _Step(nudged, ago(days: 4, hours: 1)),
          _Step(nudged, ago(days: 3)),
          _Step(nudged, ago(days: 2, hours: 1)),
          _Step(nudged, ago(days: 1, hours: 2)),
          _Step(changed, ago(hours: 20), status: IssueStatus.inProgress, note: 'Replacement slats ordered, fitting Thursday morning.'),
        ]);
    issue(301,
        roomId: 212,
        reporterId: 14,
        title: 'Window won’t lock — latch broken',
        description: 'The latch on the bedroom window came off in my hand. The window closes but won’t lock, so the room isn’t secure.',
        priority: IssuePriority.high,
        photos: const [IssuePhoto.placeholder('window latch')],
        steps: [
          _Step(reported, ago(days: 3, hours: 3), status: IssueStatus.reported),
          _Step(nudged, ago(days: 2, hours: 2)),
          _Step(nudged, ago(days: 1, hours: 3)),
          _Step(nudged, ago(hours: 5)),
        ]);
    issue(302,
        roomId: 206,
        reporterId: 12,
        title: 'Kitchen extractor fan not working',
        description: 'The fan above the hob doesn’t turn on at all, so the kitchen fills with steam and the smoke alarm keeps going off.',
        priority: IssuePriority.medium,
        steps: [
          _Step(reported, ago(days: 4, hours: 6), status: IssueStatus.reported),
          _Step(changed, ago(days: 3, hours: 20), status: IssueStatus.acknowledged),
          _Step(nudged, ago(days: 3, hours: 2)),
          _Step(nudged, ago(days: 2, hours: 4)),
        ]);
    issue(303,
        roomId: 224,
        reporterId: 15,
        title: 'Shower drains very slowly',
        description: 'Water pools around my ankles within a minute of turning the shower on. It takes ages to drain afterwards.',
        priority: IssuePriority.medium,
        photos: const [IssuePhoto.placeholder('shower tray')],
        steps: [
          _Step(reported, ago(days: 2, hours: 1), status: IssueStatus.reported),
          _Step(nudged, ago(hours: 9)),
        ]);
    issue(304,
        roomId: 201,
        reporterId: 10,
        title: 'Wardrobe door hinge loose',
        description: 'The top hinge on the left wardrobe door has pulled out of the wood and the door hangs at an angle.',
        priority: IssuePriority.low,
        steps: [
          _Step(reported, ago(days: 3, hours: 4), status: IssueStatus.reported),
          _Step(changed, ago(days: 2, hours: 22), status: IssueStatus.acknowledged),
        ]);
    issue(305,
        roomId: 207,
        reporterId: 10,
        title: 'Light pull cord snapped',
        description: 'The pull cord for the bathroom light snapped off near the ceiling, so the light can’t be switched on.',
        priority: IssuePriority.medium,
        photos: const [IssuePhoto.placeholder('pull cord')],
        steps: [_Step(reported, ago(days: 1, hours: 1), status: IssueStatus.reported)]);
    issue(306,
        roomId: 205,
        reporterId: 19,
        title: 'Radiator not heating up',
        description: 'The radiator under the window stays cold even with the heating on full.',
        priority: IssuePriority.medium,
        steps: [
          _Step(reported, ago(days: 5), status: IssueStatus.reported),
          _Step(changed, ago(days: 4, hours: 20), status: IssueStatus.acknowledged),
          _Step(changed, ago(days: 2), status: IssueStatus.inProgress, note: 'Plumber booked to bleed the system.'),
        ]);
    issue(307,
        roomId: 211,
        reporterId: 24,
        title: 'Damp patch spreading on ceiling',
        description: 'A dark damp patch has appeared above the bed and has doubled in size this week.',
        priority: IssuePriority.high,
        photos: const [IssuePhoto.placeholder('ceiling damp')],
        steps: [
          _Step(reported, ago(days: 2, hours: 8), status: IssueStatus.reported),
          _Step(nudged, ago(days: 1, hours: 4)),
        ]);
    issue(308,
        roomId: 214,
        reporterId: 23,
        title: 'Front door intercom not buzzing',
        description: 'Deliveries can’t reach us - the intercom rings upstairs but the door release does nothing.',
        priority: IssuePriority.medium,
        steps: [
          _Step(reported, ago(days: 6), status: IssueStatus.reported),
          _Step(changed, ago(days: 5), status: IssueStatus.acknowledged),
        ]);
    issue(309,
        roomId: 223,
        reporterId: 16,
        title: 'Kitchen tap dripping constantly',
        description: 'The cold tap drips even when fully closed.',
        priority: IssuePriority.low,
        steps: [
          _Step(reported, ago(days: 7), status: IssueStatus.reported),
          _Step(changed, ago(days: 6), status: IssueStatus.acknowledged),
          _Step(changed, ago(days: 1, hours: 6), status: IssueStatus.inProgress),
        ]);
    issue(310,
        roomId: 225,
        reporterId: 16,
        title: 'Hallway light flickering on 2nd floor',
        description: 'The ceiling light outside Room 3 flickers on and off all evening.',
        priority: IssuePriority.low,
        steps: [
          _Step(reported, ago(days: 12), status: IssueStatus.reported),
          _Step(changed, ago(days: 11), status: IssueStatus.acknowledged),
          _Step(changed, ago(days: 8), status: IssueStatus.resolved, note: 'New fitting installed.'),
        ]);
    issue(311,
        roomId: 201,
        reporterId: 10,
        title: 'Desk drawer runner broken',
        description: 'The top desk drawer runner snapped and the drawer falls out when opened.',
        priority: IssuePriority.low,
        steps: [
          _Step(reported, ago(days: 14), status: IssueStatus.reported),
          _Step(changed, ago(days: 12), status: IssueStatus.acknowledged),
          _Step(changed, ago(days: 8, hours: 3), status: IssueStatus.resolved, note: 'Runner replaced.'),
        ]);
  }
}

class _Step {
  const _Step(this.type, this.at, {this.status, this.note});

  final IssueEventType type;
  final DateTime at;
  final IssueStatus? status;
  final String? note;
}
