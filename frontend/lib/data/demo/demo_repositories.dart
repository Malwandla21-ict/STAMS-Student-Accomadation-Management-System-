import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../models/property.dart';
import '../../models/student_home.dart';
import '../../models/user.dart';
import '../api_client.dart';
import '../repositories.dart';
import 'demo_store.dart';

/// Small delay so loading states are visible, like a real network call.
Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 350));

ApiException _notFound(String what) => ApiException('$what not found', statusCode: 404);

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._store);

  final DemoStore _store;

  @override
  Future<AppUser?> restore() async => _store.users[_store.signedInUserId]?.toAppUser();

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await _latency();
    final user = _store.users.values.where((u) => u.email == email.trim().toLowerCase()).firstOrNull;
    if (user == null || user.password != password) {
      throw const ApiException('Incorrect email or password', statusCode: 401);
    }
    _store.signedInUserId = user.id;
    return user.toAppUser();
  }

  @override
  Future<AppUser> signUp({required String name, required String email, required String password, required Role role}) async {
    await _latency();
    final normalised = email.trim().toLowerCase();
    if (_store.users.values.any((u) => u.email == normalised)) {
      throw const ApiException('An account with this email already exists', statusCode: 409);
    }
    final user = DemoUser(id: _store.nextId(), name: name.trim(), email: normalised, role: role, password: password);
    _store.users[user.id] = user;
    _store.signedInUserId = user.id;
    return user.toAppUser();
  }

  @override
  Future<void> signOut() async => _store.signedInUserId = null;
}

class DemoPropertyRepository implements PropertyRepository {
  DemoPropertyRepository(this._store);

  final DemoStore _store;

  int get _me => _store.signedInUserId!;

  DemoProperty _mine(int id) {
    final p = _store.properties[id];
    if (p == null || p.landlordId != _me) throw _notFound('Property');
    return p;
  }

  @override
  Future<List<Property>> list() async {
    await _latency();
    return _store.properties.values.where((p) => p.landlordId == _me).map((p) => _store.propertyView(p.id)).toList();
  }

  @override
  Future<Property> get(int id) async {
    await _latency();
    return _store.propertyView(_mine(id).id, withRooms: true);
  }

  @override
  Future<Property> create(PropertyInput input) async {
    await _latency();
    final p = DemoProperty(id: _store.nextId(), landlordId: _me, input: input, createdAt: DateTime.now());
    _store.properties[p.id] = p;
    return _store.propertyView(p.id);
  }

  @override
  Future<Property> update(int id, PropertyInput input) async {
    await _latency();
    _mine(id).input = input;
    return _store.propertyView(id);
  }

  @override
  Future<void> delete(int id) async {
    await _latency();
    _mine(id);
    final roomIds = _store.rooms.values.where((r) => r.propertyId == id).map((r) => r.id).toSet();
    if (_store.users.values.any((u) => roomIds.contains(u.roomId))) {
      throw const ApiException('Move or remove the students living here before deleting this property.', statusCode: 409);
    }
    if (_store.issues.values.any((i) => i.propertyId == id && i.isOpen)) {
      throw const ApiException('Resolve the open issues at this property before deleting it.', statusCode: 409);
    }
    _store.rooms.removeWhere((_, r) => r.propertyId == id);
    _store.issues.removeWhere((_, i) => i.propertyId == id);
    _store.properties.remove(id);
  }

  @override
  Future<Room> createRoom(int propertyId, RoomInput input) async {
    await _latency();
    _mine(propertyId);
    final r = DemoRoom(id: _store.nextId(), propertyId: propertyId, input: input);
    _store.rooms[r.id] = r;
    return _store.roomView(r.id);
  }
}

class DemoRoomRepository implements RoomRepository {
  DemoRoomRepository(this._store);

  final DemoStore _store;

  int get _me => _store.signedInUserId!;

  DemoRoom _mine(int id) {
    final r = _store.rooms[id];
    if (r == null || _store.properties[r.propertyId]?.landlordId != _me) throw _notFound('Room');
    return r;
  }

  @override
  Future<Room> get(int id) async {
    await _latency();
    return _store.roomView(_mine(id).id);
  }

  @override
  Future<Room> update(int id, RoomInput input) async {
    await _latency();
    final r = _mine(id);
    final occupied = _store.studentsIn(id).length;
    final capacity = input.effectiveCapacity;
    if (input.occupancyMode == OccupancyMode.communal && occupied > 0) {
      throw const ApiException('Remove the students in this room before making it communal.', statusCode: 409);
    }
    if (capacity != null && occupied > capacity) {
      throw ApiException('$occupied students live here - capacity can’t go below that.', statusCode: 409);
    }
    r.input = input;
    return _store.roomView(id);
  }

  @override
  Future<void> delete(int id) async {
    await _latency();
    _mine(id);
    if (_store.studentsIn(id).isNotEmpty) {
      throw const ApiException('Remove the students in this room before deleting it.', statusCode: 409);
    }
    if (_store.openIssuesIn(id) > 0) {
      throw const ApiException('Resolve the open issues in this room before deleting it.', statusCode: 409);
    }
    _store.rooms.remove(id);
  }

  @override
  Future<Room> assignStudent(int roomId, int studentId) async {
    await _latency();
    final r = _mine(roomId);
    final room = _store.roomView(roomId);
    if (room.isCommunal) throw const ApiException('Students can’t be assigned to a communal room.', statusCode: 400);
    if (room.isFull) throw const ApiException('This room is full.', statusCode: 409);
    final student = _store.users[studentId];
    if (student == null || student.role != Role.student) throw _notFound('Student');
    final current = student.roomId;
    if (current != null && _store.landlordOfRoom(current) != _me) {
      throw const ApiException('This student lives in another landlord’s property.', statusCode: 409);
    }
    student.roomId = roomId;
    final property = _store.properties[r.propertyId]!;
    _store.notify(studentId, (id) => AppNotification(
          id: id,
          type: NotificationType.roomAssigned,
          message: 'You’ve been added to ${r.input.name} at ${property.input.name}',
          createdAt: DateTime.now(),
          actorName: _store.users[_me]!.name,
          roomName: r.input.name,
          propertyName: property.input.name,
        ));
    return _store.roomView(roomId);
  }

  @override
  Future<Room> removeStudent(int roomId, int studentId) async {
    await _latency();
    _mine(roomId);
    final student = _store.users[studentId];
    if (student?.roomId == roomId) student!.roomId = null;
    return _store.roomView(roomId);
  }

  @override
  Future<List<StudentSearchResult>> searchStudents(String email) async {
    await _latency();
    final q = email.trim().toLowerCase();
    if (q.length < 2) return const [];
    return _store.users.values.where((u) => u.role == Role.student && u.email.contains(q)).map((u) {
      final roomId = u.roomId;
      if (roomId == null) {
        return StudentSearchResult(id: u.id, name: u.name, email: u.email, placement: Placement.notInARoom);
      }
      if (_store.landlordOfRoom(roomId) != _me) {
        return StudentSearchResult(id: u.id, name: u.name, email: u.email, placement: Placement.withAnotherLandlord);
      }
      final room = _store.roomView(roomId);
      return StudentSearchResult(
        id: u.id,
        name: u.name,
        email: u.email,
        placement: Placement.inYourProperty,
        currentRoomId: room.id,
        currentRoomName: room.name,
        currentPropertyName: room.propertyName,
      );
    }).toList();
  }
}

class DemoIssueRepository implements IssueRepository {
  DemoIssueRepository(this._store);

  final DemoStore _store;

  Issue _issue(int id) => _store.issues[id] ?? (throw _notFound('Issue'));

  @override
  Future<List<Issue>> listForLandlord(int landlordId) async {
    await _latency();
    final mine = _store.properties.values.where((p) => p.landlordId == landlordId).map((p) => p.id).toSet();
    return _store.issues.values.where((i) => mine.contains(i.propertyId)).toList();
  }

  @override
  Future<List<Issue>> listForStudent(int studentId) async {
    await _latency();
    return _store.issues.values.where((i) => i.reporterId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Issue>> listForRoom(int roomId) async {
    await _latency();
    return _store.issues.values.where((i) => i.roomId == roomId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Issue> get(int id) async {
    await _latency();
    return _issue(id);
  }

  @override
  Future<Issue> create(NewIssue input, {required int reporterId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final room = _store.rooms[input.roomId] ?? (throw _notFound('Room'));
    final property = _store.properties[room.propertyId]!;
    final reporter = _store.users[reporterId]!;
    final now = DateTime.now();
    final id = _store.nextId();
    final issue = Issue(
      id: id,
      title: input.title.trim(),
      description: input.description.trim(),
      status: IssueStatus.reported,
      priority: IssuePriority.medium,
      roomId: room.id,
      roomName: room.input.name,
      roomType: room.input.type,
      propertyId: property.id,
      propertyName: property.input.name,
      reporterId: reporter.id,
      reporterName: reporter.name,
      landlordName: _store.users[property.landlordId]!.name,
      createdAt: now,
      photos: input.photos.map(IssuePhoto.bytes).toList(),
      events: [
        IssueEvent(
          id: _store.nextId(),
          type: IssueEventType.reported,
          actorId: reporter.id,
          actorName: reporter.name,
          createdAt: now,
          status: IssueStatus.reported,
        ),
      ],
    );
    _store.issues[id] = issue;
    return issue;
  }

  @override
  Future<Issue> update(int id, IssueUpdate update, {required int landlordId}) async {
    await _latency();
    final issue = _issue(id);
    if (update.status.index < issue.status.index) {
      throw const ApiException('An issue can only move forward.', statusCode: 400);
    }
    final landlord = _store.users[landlordId]!;
    final now = DateTime.now();
    final note = update.note?.trim();
    final events = [...issue.events];
    IssueEvent event(IssueEventType type, {IssueStatus? status, IssuePriority? priority, String? note}) => IssueEvent(
          id: _store.nextId(),
          type: type,
          actorId: landlord.id,
          actorName: landlord.name,
          createdAt: now,
          status: status,
          priority: priority,
          note: note,
        );

    final statusChanged = update.status != issue.status;
    if (update.priority != issue.priority) {
      events.add(event(IssueEventType.priorityChanged, priority: update.priority));
    }
    if (statusChanged) {
      events.add(event(IssueEventType.statusChanged, status: update.status, note: note?.isEmpty == true ? null : note));
    } else if (note != null && note.isNotEmpty) {
      events.add(event(IssueEventType.noteAdded, note: note));
    }

    final updated = issue.copyWith(
      status: update.status,
      priority: update.priority,
      resolvedAt: update.status == IssueStatus.resolved && statusChanged ? now : null,
      events: events,
    );
    _store.issues[id] = updated;

    if (statusChanged) {
      _store.notify(issue.reporterId, (nid) => AppNotification(
            id: nid,
            type: NotificationType.statusChange,
            message: '${landlord.name} moved your issue to ${update.status.label}',
            createdAt: now,
            actorName: landlord.name,
            issueId: id,
            issueTitle: issue.title,
            roomName: issue.roomName,
            propertyName: issue.propertyName,
            status: update.status,
          ));
    }
    return updated;
  }

  @override
  Future<Issue> nudge(int id, {required int studentId}) async {
    await _latency();
    final issue = _issue(id);
    final now = DateTime.now();
    if (!issue.isOpen) throw const ApiException('Resolved issues can’t be nudged.', statusCode: 400);
    if (issue.reporterId != studentId) throw const ApiException('Only the student who reported this can nudge.', statusCode: 403);
    if (issue.nextNudgeAt(now) != null) {
      throw const ApiException('You can nudge once every 24 hours.', statusCode: 429);
    }
    final student = _store.users[studentId]!;
    final number = issue.nudgeCount + 1;
    final updated = issue.copyWith(
      nudgeCount: number,
      lastNudgedAt: now,
      events: [
        ...issue.events,
        IssueEvent(
          id: _store.nextId(),
          type: IssueEventType.nudged,
          actorId: student.id,
          actorName: student.name,
          createdAt: now,
          nudgeNumber: number,
        ),
      ],
    );
    _store.issues[id] = updated;
    _store.notify(_store.landlordOfRoom(issue.roomId), (nid) => AppNotification(
          id: nid,
          type: NotificationType.nudge,
          message: '${student.name} nudged you',
          createdAt: now,
          actorName: student.name,
          issueId: id,
          issueTitle: issue.title,
          roomName: issue.roomName,
          propertyName: issue.propertyName,
          nudgeNumber: number,
        ));
    return updated;
  }
}

class DemoNotificationRepository implements NotificationRepository {
  DemoNotificationRepository(this._store);

  final DemoStore _store;

  @override
  Future<List<AppNotification>> list(int userId) async {
    await _latency();
    return _store.notifications.values.where((n) => n.recipientId == userId).map((n) => n.notification).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markRead(int id) async {
    final n = _store.notifications[id];
    if (n != null) n.notification = n.notification.markRead();
  }

  @override
  Future<void> markAllRead(int userId) async {
    for (final n in _store.notifications.values.where((n) => n.recipientId == userId)) {
      n.notification = n.notification.markRead();
    }
  }
}

class DemoStudentHomeRepository implements StudentHomeRepository {
  DemoStudentHomeRepository(this._store);

  final DemoStore _store;

  @override
  Future<StudentHome?> homeFor(int studentId) async {
    await _latency();
    final roomId = _store.users[studentId]?.roomId;
    if (roomId == null) return null;
    final room = _store.roomView(roomId);
    final property = _store.properties[room.propertyId]!;
    return StudentHome(
      room: room,
      propertyName: property.input.name,
      landlordName: _store.users[property.landlordId]!.name,
      roommates: room.students.where((s) => s.id != studentId).toList(),
      sharedSpaces: _store.rooms.values
          .where((r) => r.propertyId == property.id && r.input.occupancyMode == OccupancyMode.communal)
          .map((r) => _store.roomView(r.id))
          .toList(),
    );
  }
}
