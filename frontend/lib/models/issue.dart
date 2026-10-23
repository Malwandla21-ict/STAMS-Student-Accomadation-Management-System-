import 'dart:typed_data';

import '../config.dart';
import 'enums.dart';

const nudgeCooldown = Duration(hours: 24);
const maxIssuePhotos = 3;

/// A photo is either a URL from the server or bytes picked on this device.
class IssuePhoto {
  const IssuePhoto.url(String this.url)
      : bytes = null,
        label = null;
  const IssuePhoto.bytes(Uint8List this.bytes)
      : url = null,
        label = null;

  /// Demo data only: renders the striped placeholder with a caption.
  const IssuePhoto.placeholder(String this.label)
      : url = null,
        bytes = null;

  final String? url;
  final Uint8List? bytes;
  final String? label;
}

class Issue {
  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.propertyId,
    required this.propertyName,
    required this.reporterId,
    required this.reporterName,
    required this.landlordName,
    required this.createdAt,
    this.photos = const [],
    this.nudgeCount = 0,
    this.lastNudgedAt,
    this.resolvedAt,
    this.events = const [],
  });

  final int id;
  final String title;
  final String description;
  final IssueStatus status;
  final IssuePriority priority;
  final int roomId;
  final String roomName;
  final RoomType roomType;
  final int propertyId;
  final String propertyName;
  final int reporterId;
  final String reporterName;
  final String landlordName;
  final DateTime createdAt;
  final List<IssuePhoto> photos;
  final int nudgeCount;
  final DateTime? lastNudgedAt;
  final DateTime? resolvedAt;

  /// Timeline, oldest first (same order as the backend).
  final List<IssueEvent> events;

  factory Issue.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) => json[key] == null ? null : DateTime.parse(json[key] as String).toLocal();
    return Issue(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: enumFromJson(IssueStatus.values, json['status']),
      priority: enumFromJson(IssuePriority.values, json['priority']),
      roomId: (json['roomId'] as num).toInt(),
      roomName: json['roomName'] as String,
      roomType: enumFromJson(RoomType.values, json['roomType']),
      propertyId: (json['propertyId'] as num).toInt(),
      propertyName: json['propertyName'] as String,
      reporterId: (json['reporterId'] as num).toInt(),
      reporterName: json['reporterName'] as String,
      landlordName: json['landlordName'] as String,
      createdAt: time('createdAt')!,
      photos: (json['photoUrls'] as List? ?? const []).map((u) => IssuePhoto.url(absoluteApiUrl(u as String))).toList(),
      nudgeCount: (json['nudgeCount'] as num? ?? 0).toInt(),
      lastNudgedAt: time('lastNudgedAt'),
      resolvedAt: time('resolvedAt'),
      events: (json['events'] as List? ?? const []).map((e) => IssueEvent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  bool get isOpen => status.isOpen;
  String get location => '$roomName · $propertyName';

  /// When the student may nudge again, or null if they can nudge now.
  DateTime? nextNudgeAt(DateTime now) {
    if (lastNudgedAt == null) return null;
    final next = lastNudgedAt!.add(nudgeCooldown);
    return next.isAfter(now) ? next : null;
  }

  Issue copyWith({
    IssueStatus? status,
    IssuePriority? priority,
    int? nudgeCount,
    DateTime? lastNudgedAt,
    DateTime? resolvedAt,
    List<IssueEvent>? events,
  }) =>
      Issue(
        id: id,
        title: title,
        description: description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        roomId: roomId,
        roomName: roomName,
        roomType: roomType,
        propertyId: propertyId,
        propertyName: propertyName,
        reporterId: reporterId,
        reporterName: reporterName,
        landlordName: landlordName,
        createdAt: createdAt,
        photos: photos,
        nudgeCount: nudgeCount ?? this.nudgeCount,
        lastNudgedAt: lastNudgedAt ?? this.lastNudgedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        events: events ?? this.events,
      );
}

/// One step on an issue's timeline. Which of status / priority / nudgeNumber
/// is filled depends on [type].
class IssueEvent {
  const IssueEvent({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    this.status,
    this.priority,
    this.note,
    this.nudgeNumber,
  });

  final int id;
  final IssueEventType type;
  final int actorId;
  final String actorName;
  final DateTime createdAt;
  final IssueStatus? status;
  final IssuePriority? priority;
  final String? note;
  final int? nudgeNumber;

  factory IssueEvent.fromJson(Map<String, dynamic> json) => IssueEvent(
        id: (json['id'] as num).toInt(),
        type: enumFromJson(IssueEventType.values, json['type']),
        actorId: (json['actorId'] as num).toInt(),
        actorName: json['actorName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        status: json['status'] == null ? null : enumFromJson(IssueStatus.values, json['status']),
        priority: json['priority'] == null ? null : enumFromJson(IssuePriority.values, json['priority']),
        note: json['note'] as String?,
        nudgeNumber: (json['nudgeNumber'] as num?)?.toInt(),
      );
}

/// What the student submits from S2/S3.
class NewIssue {
  const NewIssue({required this.roomId, required this.title, required this.description, this.photos = const []});

  final int roomId;
  final String title;
  final String description;
  final List<Uint8List> photos;
}

/// What the landlord saves from the L4 sheet.
class IssueUpdate {
  const IssueUpdate({required this.status, required this.priority, this.note});

  final IssueStatus status;
  final IssuePriority priority;
  final String? note;
}

class IssueFilter {
  const IssueFilter({this.status, this.priorities = const {}, this.propertyId, this.sort = IssueSort.mostNudged, this.query = ''});

  /// Null means "all open issues".
  final IssueStatus? status;

  /// Empty means any priority.
  final Set<IssuePriority> priorities;
  final int? propertyId;
  final IssueSort sort;
  final String query;

  bool get hasNarrowing => priorities.isNotEmpty || propertyId != null;

  IssueFilter copyWith({
    IssueStatus? Function()? status,
    Set<IssuePriority>? priorities,
    int? Function()? propertyId,
    IssueSort? sort,
    String? query,
  }) =>
      IssueFilter(
        status: status != null ? status() : this.status,
        priorities: priorities ?? this.priorities,
        propertyId: propertyId != null ? propertyId() : this.propertyId,
        sort: sort ?? this.sort,
        query: query ?? this.query,
      );

  bool matches(Issue issue) {
    if (status == null ? !issue.isOpen : issue.status != status) return false;
    if (priorities.isNotEmpty && !priorities.contains(issue.priority)) return false;
    if (propertyId != null && issue.propertyId != propertyId) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final haystack = '${issue.title} ${issue.reporterName} ${issue.roomName} ${issue.propertyName}'.toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    return true;
  }

  List<Issue> apply(Iterable<Issue> issues) {
    final list = issues.where(matches).toList();
    switch (sort) {
      case IssueSort.mostNudged:
        list.sort((a, b) {
          final byCount = b.nudgeCount.compareTo(a.nudgeCount);
          if (byCount != 0) return byCount;
          final aLast = a.lastNudgedAt ?? a.createdAt;
          final bLast = b.lastNudgedAt ?? b.createdAt;
          return bLast.compareTo(aLast);
        });
      case IssueSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case IssueSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }
}
