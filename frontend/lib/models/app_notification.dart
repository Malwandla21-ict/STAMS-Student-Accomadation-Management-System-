import 'enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.actorName,
    this.issueId,
    this.issueTitle,
    this.roomName,
    this.propertyName,
    this.status,
    this.nudgeNumber,
  });

  final int id;
  final NotificationType type;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? actorName;
  final int? issueId;
  final String? issueTitle;
  final String? roomName;
  final String? propertyName;

  /// The status the issue moved to (status changes only).
  final IssueStatus? status;

  /// 1 for the first nudge on the issue (nudges only).
  final int? nudgeNumber;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] as num).toInt(),
        type: enumFromJson(NotificationType.values, json['type']),
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        read: json['read'] as bool? ?? false,
        actorName: json['actorName'] as String?,
        issueId: (json['issueId'] as num?)?.toInt(),
        issueTitle: json['issueTitle'] as String?,
        roomName: json['roomName'] as String?,
        propertyName: json['propertyName'] as String?,
        status: json['status'] == null ? null : enumFromJson(IssueStatus.values, json['status']),
        nudgeNumber: (json['nudgeNumber'] as num?)?.toInt(),
      );

  AppNotification markRead() => AppNotification(
        id: id,
        type: type,
        message: message,
        createdAt: createdAt,
        read: true,
        actorName: actorName,
        issueId: issueId,
        issueTitle: issueTitle,
        roomName: roomName,
        propertyName: propertyName,
        status: status,
        nudgeNumber: nudgeNumber,
      );
}
