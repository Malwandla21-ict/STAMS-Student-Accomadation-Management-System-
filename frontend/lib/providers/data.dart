import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../models/enums.dart';
import '../models/issue.dart';
import '../models/property.dart';
import '../models/student_home.dart';
import '../models/user.dart';
import 'repositories.dart';

// ---------------------------------------------------------------------------
// Issues
// ---------------------------------------------------------------------------

final landlordIssuesProvider = FutureProvider<List<Issue>>(
  (ref) => ref.watch(issueRepositoryProvider).listForLandlord(ref.watch(actingUserIdProvider)),
);

final studentIssuesProvider = FutureProvider<List<Issue>>(
  (ref) => ref.watch(issueRepositoryProvider).listForStudent(ref.watch(actingUserIdProvider)),
);

final issueProvider = FutureProvider.autoDispose.family<Issue, int>(
  (ref, id) => ref.watch(issueRepositoryProvider).get(id),
);

final roomIssuesProvider = FutureProvider.autoDispose.family<List<Issue>, int>(
  (ref, roomId) => ref.watch(issueRepositoryProvider).listForRoom(roomId),
);

/// L2 filters. Survives tab switches so the landlord's choices stick.
class IssueFilterController extends Notifier<IssueFilter> {
  @override
  IssueFilter build() => const IssueFilter();

  void set(IssueFilter filter) => state = filter;
  void setStatus(IssueStatus? status) => state = state.copyWith(status: () => status);
  void setQuery(String query) => state = state.copyWith(query: query);
  void clearNarrowing() => state = state.copyWith(priorities: const {}, propertyId: () => null);
  void removePriority(IssuePriority p) => state = state.copyWith(priorities: {...state.priorities}..remove(p));
  void clearProperty() => state = state.copyWith(propertyId: () => null);
}

final issueFilterProvider = NotifierProvider<IssueFilterController, IssueFilter>(IssueFilterController.new);

final filteredLandlordIssuesProvider = Provider<AsyncValue<List<Issue>>>((ref) {
  final filter = ref.watch(issueFilterProvider);
  return ref.watch(landlordIssuesProvider).whenData(filter.apply);
});

/// Bottom-nav "Issues" badge: open issues that students have nudged.
final nudgedOpenIssueCountProvider = Provider<int>((ref) {
  final issues = ref.watch(landlordIssuesProvider).value ?? const [];
  return issues.where((i) => i.isOpen && i.nudgeCount > 0).length;
});

// ---------------------------------------------------------------------------
// Properties & rooms
// ---------------------------------------------------------------------------

final propertiesProvider = FutureProvider<List<Property>>((ref) {
  ref.watch(actingUserIdProvider); // refetch on account change
  return ref.watch(propertyRepositoryProvider).list();
});

final propertyProvider = FutureProvider.autoDispose.family<Property, int>(
  (ref, id) => ref.watch(propertyRepositoryProvider).get(id),
);

final roomProvider = FutureProvider.autoDispose.family<Room, int>(
  (ref, id) => ref.watch(roomRepositoryProvider).get(id),
);

final studentSearchProvider = FutureProvider.autoDispose.family<List<StudentSearchResult>, String>((ref, query) async {
  if (query.trim().length < 2) return const [];
  // Debounce: wait for typing to pause, and bail out if the query changed meanwhile.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (cancelled) return const [];
  return ref.watch(roomRepositoryProvider).searchStudents(query.trim());
});

// ---------------------------------------------------------------------------
// Alerts & student home
// ---------------------------------------------------------------------------

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).list(ref.watch(actingUserIdProvider)),
);

final unreadAlertCountProvider = Provider<int>(
  (ref) => (ref.watch(notificationsProvider).value ?? const []).where((n) => !n.read).length,
);

final studentHomeProvider = FutureProvider<StudentHome?>(
  (ref) => ref.watch(studentHomeRepositoryProvider).homeFor(ref.watch(actingUserIdProvider)),
);

// ---------------------------------------------------------------------------
// Mutations. Each one refreshes whatever lists it affects.
// ---------------------------------------------------------------------------

class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  int get _me => _ref.read(actingUserIdProvider);

  void _refreshIssues() {
    _ref.invalidate(landlordIssuesProvider);
    _ref.invalidate(studentIssuesProvider);
    _ref.invalidate(issueProvider);
    _ref.invalidate(roomIssuesProvider);
    _ref.invalidate(notificationsProvider);
  }

  void _refreshPlaces() {
    _ref.invalidate(propertiesProvider);
    _ref.invalidate(propertyProvider);
    _ref.invalidate(roomProvider);
    _ref.invalidate(studentSearchProvider);
    _ref.invalidate(studentHomeProvider);
  }

  Future<Issue> reportIssue(NewIssue issue) async {
    final created = await _ref.read(issueRepositoryProvider).create(issue, reporterId: _me);
    _refreshIssues();
    return created;
  }

  Future<Issue> updateIssue(int id, IssueUpdate update) async {
    final updated = await _ref.read(issueRepositoryProvider).update(id, update, landlordId: _me);
    _refreshIssues();
    _refreshPlaces();
    return updated;
  }

  Future<Issue> nudge(int id) async {
    final updated = await _ref.read(issueRepositoryProvider).nudge(id, studentId: _me);
    _refreshIssues();
    return updated;
  }

  Future<Property> saveProperty(int? id, PropertyInput input) async {
    final repo = _ref.read(propertyRepositoryProvider);
    final saved = id == null ? await repo.create(input) : await repo.update(id, input);
    _refreshPlaces();
    return saved;
  }

  Future<void> deleteProperty(int id) async {
    await _ref.read(propertyRepositoryProvider).delete(id);
    _refreshPlaces();
  }

  Future<Room> saveRoom({required int propertyId, int? roomId, required RoomInput input}) async {
    final saved = roomId == null
        ? await _ref.read(propertyRepositoryProvider).createRoom(propertyId, input)
        : await _ref.read(roomRepositoryProvider).update(roomId, input);
    _refreshPlaces();
    return saved;
  }

  Future<void> deleteRoom(int id) async {
    await _ref.read(roomRepositoryProvider).delete(id);
    _refreshPlaces();
  }

  Future<Room> assignStudent(int roomId, int studentId) async {
    final room = await _ref.read(roomRepositoryProvider).assignStudent(roomId, studentId);
    _refreshPlaces();
    return room;
  }

  Future<Room> removeStudent(int roomId, int studentId) async {
    final room = await _ref.read(roomRepositoryProvider).removeStudent(roomId, studentId);
    _refreshPlaces();
    return room;
  }

  Future<void> markAlertRead(int id) async {
    await _ref.read(notificationRepositoryProvider).markRead(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllAlertsRead() async {
    await _ref.read(notificationRepositoryProvider).markAllRead(_me);
    _ref.invalidate(notificationsProvider);
  }
}

final actionsProvider = Provider<AppActions>(AppActions.new);

// ---------------------------------------------------------------------------
// Report-an-issue draft (S2 -> S3)
// ---------------------------------------------------------------------------

class ReportDraft {
  const ReportDraft({this.roomId, this.photos = const []});

  final int? roomId;
  final List<Uint8List> photos;

  ReportDraft copyWith({int? roomId, List<Uint8List>? photos}) =>
      ReportDraft(roomId: roomId ?? this.roomId, photos: photos ?? this.photos);
}

class ReportDraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void selectRoom(int roomId) => state = state.copyWith(roomId: roomId);
  void addPhoto(Uint8List bytes) {
    if (state.photos.length < maxIssuePhotos) state = state.copyWith(photos: [...state.photos, bytes]);
  }

  void removePhoto(int index) => state = state.copyWith(photos: [...state.photos]..removeAt(index));
  void reset() => state = const ReportDraft();
}

final reportDraftProvider = NotifierProvider<ReportDraftController, ReportDraft>(ReportDraftController.new);
