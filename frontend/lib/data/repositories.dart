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

/// No backend endpoints yet - the ids say whose view to build. A real
/// implementation can ignore them and rely on the JWT instead.
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
