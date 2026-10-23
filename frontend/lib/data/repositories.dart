import '../models/app_notification.dart';
import '../models/enums.dart';
import '../models/issue.dart';
import '../models/property.dart';
import '../models/student_home.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'token_store.dart';

// ---------------------------------------------------------------------------
// Interfaces. Screens only ever talk to these.
// ---------------------------------------------------------------------------

abstract interface class AuthRepository {
  /// Returns the signed-in user if a saved token is still valid.
  Future<AppUser?> restore();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String name, required String email, required String password, required Role role});
  Future<void> signOut();
}

abstract interface class PropertyRepository {
  Future<List<Property>> list();

  /// Includes the property's rooms.
  Future<Property> get(int id);
  Future<Property> create(PropertyInput input);
  Future<Property> update(int id, PropertyInput input);
  Future<void> delete(int id);
  Future<Room> createRoom(int propertyId, RoomInput input);
}

abstract interface class RoomRepository {
  Future<Room> get(int id);
  Future<Room> update(int id, RoomInput input);
  Future<void> delete(int id);
  Future<Room> assignStudent(int roomId, int studentId);
  Future<Room> removeStudent(int roomId, int studentId);
  Future<List<StudentSearchResult>> searchStudents(String email);
}

/// The ids say whose data to use. The demo store needs them; the API versions ignore
/// them because the backend reads the signed-in user from the token.
abstract interface class IssueRepository {
  Future<List<Issue>> listForLandlord(int landlordId);
  Future<List<Issue>> listForStudent(int studentId);
  Future<List<Issue>> listForRoom(int roomId);
  Future<Issue> get(int id);
  Future<Issue> create(NewIssue issue, {required int reporterId});
  Future<Issue> update(int id, IssueUpdate update, {required int landlordId});
  Future<Issue> nudge(int id, {required int studentId});
}

abstract interface class NotificationRepository {
  Future<List<AppNotification>> list(int userId);
  Future<void> markRead(int id);
  Future<void> markAllRead(int userId);
}

abstract interface class StudentHomeRepository {
  /// Null while the student hasn't been assigned to a room (S1u).
  Future<StudentHome?> homeFor(int studentId);
}

// ---------------------------------------------------------------------------
// Spring backend implementations.
// ---------------------------------------------------------------------------

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<AppUser?> restore() async {
    if (await _tokens.read() == null) return null;
    try {
      final json = await _api.get<Map<String, dynamic>>('/api/me');
      return AppUser.fromJson(json);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _authenticate('/api/auth/login', {'email': email.trim(), 'password': password});

  @override
  Future<AppUser> signUp({required String name, required String email, required String password, required Role role}) =>
      _authenticate('/api/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': enumToJson(role),
      });

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final json = await _api.post<Map<String, dynamic>>(path, body: body);
    await _tokens.write(json['token'] as String);
    return AppUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> signOut() => _tokens.clear();
}

class ApiPropertyRepository implements PropertyRepository {
  ApiPropertyRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Property>> list() async {
    final json = await _api.get<List<dynamic>>('/api/properties');
    return json.map((p) => Property.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<Property> get(int id) async => Property.fromJson(await _api.get<Map<String, dynamic>>('/api/properties/$id'));

  @override
  Future<Property> create(PropertyInput input) async =>
      Property.fromJson(await _api.post<Map<String, dynamic>>('/api/properties', body: input.toJson()));

  @override
  Future<Property> update(int id, PropertyInput input) async =>
      Property.fromJson(await _api.put<Map<String, dynamic>>('/api/properties/$id', body: input.toJson()));

  @override
  Future<void> delete(int id) => _api.delete('/api/properties/$id');

  @override
  Future<Room> createRoom(int propertyId, RoomInput input) async =>
      Room.fromJson(await _api.post<Map<String, dynamic>>('/api/properties/$propertyId/rooms', body: input.toJson()));
}

class ApiRoomRepository implements RoomRepository {
  ApiRoomRepository(this._api);

  final ApiClient _api;

  @override
  Future<Room> get(int id) async => Room.fromJson(await _api.get<Map<String, dynamic>>('/api/rooms/$id'));

  @override
  Future<Room> update(int id, RoomInput input) async =>
      Room.fromJson(await _api.put<Map<String, dynamic>>('/api/rooms/$id', body: input.toJson()));

  @override
  Future<void> delete(int id) => _api.delete('/api/rooms/$id');

  @override
  Future<Room> assignStudent(int roomId, int studentId) async =>
      Room.fromJson(await _api.post<Map<String, dynamic>>('/api/rooms/$roomId/students', body: {'studentId': studentId}));

  @override
  Future<Room> removeStudent(int roomId, int studentId) async {
    // The backend returns the updated room from DELETE, so go through Dio directly.
    final json = await _api.deleteWithBody<Map<String, dynamic>>('/api/rooms/$roomId/students/$studentId');
    return Room.fromJson(json);
  }

  @override
  Future<List<StudentSearchResult>> searchStudents(String email) async {
    final json = await _api.get<List<dynamic>>('/api/students/search', query: {'email': email});
    return json.map((s) => StudentSearchResult.fromJson(s as Map<String, dynamic>)).toList();
  }
}

class ApiIssueRepository implements IssueRepository {
  ApiIssueRepository(this._api);

  final ApiClient _api;

  List<Issue> _list(List<dynamic> json) => json.map((i) => Issue.fromJson(i as Map<String, dynamic>)).toList();

  // The backend works out whose issues to return from the token, so the ids are ignored.
  @override
  Future<List<Issue>> listForLandlord(int landlordId) async => _list(await _api.get<List<dynamic>>('/api/issues'));

  @override
  Future<List<Issue>> listForStudent(int studentId) async => _list(await _api.get<List<dynamic>>('/api/issues'));

  @override
  Future<List<Issue>> listForRoom(int roomId) async => _list(await _api.get<List<dynamic>>('/api/rooms/$roomId/issues'));

  @override
  Future<Issue> get(int id) async => Issue.fromJson(await _api.get<Map<String, dynamic>>('/api/issues/$id'));

  @override
  Future<Issue> create(NewIssue issue, {required int reporterId}) async {
    final urls = <String>[];
    for (final (i, bytes) in issue.photos.indexed) {
      final json = await _api.upload<Map<String, dynamic>>('/api/uploads', bytes, filename: 'photo-${i + 1}.jpg');
      urls.add(json['url'] as String);
    }
    final json = await _api.post<Map<String, dynamic>>('/api/issues', body: {
      'roomId': issue.roomId,
      'title': issue.title,
      'description': issue.description,
      'photoUrls': urls,
    });
    return Issue.fromJson(json);
  }

  @override
  Future<Issue> update(int id, IssueUpdate update, {required int landlordId}) async =>
      Issue.fromJson(await _api.patch<Map<String, dynamic>>('/api/issues/$id', body: {
        'status': enumToJson(update.status),
        'priority': enumToJson(update.priority),
        if (update.note != null) 'note': update.note,
      }));

  @override
  Future<Issue> nudge(int id, {required int studentId}) async =>
      Issue.fromJson(await _api.post<Map<String, dynamic>>('/api/issues/$id/nudge'));
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> list(int userId) async {
    final json = await _api.get<List<dynamic>>('/api/notifications');
    return json.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markRead(int id) => _api.post<void>('/api/notifications/$id/read');

  @override
  Future<void> markAllRead(int userId) => _api.post<void>('/api/notifications/read-all');
}

class ApiStudentHomeRepository implements StudentHomeRepository {
  ApiStudentHomeRepository(this._api);

  final ApiClient _api;

  @override
  Future<StudentHome?> homeFor(int studentId) async {
    final json = await _api.getOrNull<Map<String, dynamic>>('/api/me/room');
    return json == null ? null : StudentHome.fromJson(json);
  }
}
