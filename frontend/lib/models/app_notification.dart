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
