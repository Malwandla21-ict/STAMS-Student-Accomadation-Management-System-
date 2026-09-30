/// Enums mirror the Spring backend. JSON uses SCREAMING_SNAKE_CASE
/// (e.g. IN_PROGRESS), Dart uses camelCase (inProgress).
library;

T enumFromJson<T extends Enum>(List<T> values, Object? json) {
  final camel = (json as String).toLowerCase().replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
  return values.byName(camel);
}

String enumToJson(Enum value) =>
    value.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]}').toUpperCase();

enum Role {
  landlord,
  student;

  String get label => this == landlord ? 'Landlord' : 'Student';
}

/// Declared in lifecycle order - the landlord moves an issue forward through these.
enum IssueStatus {
  reported('Reported'),
  acknowledged('Acknowledged'),
  inProgress('In progress'),
  resolved('Resolved');

  const IssueStatus(this.label);
  final String label;

  bool get isOpen => this != resolved;

  static List<IssueStatus> get open => values.where((s) => s.isOpen).toList();
}

enum IssuePriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const IssuePriority(this.label);
  final String label;
}

enum RoomType {
  bedroom('Bedroom', 'bedroom', 'Bedrooms'),
  kitchen('Kitchen', 'kitchen', 'Kitchen'),
  bathroom('Bathroom', 'bathroom', 'Bathrooms'),
  commonArea('Common area', 'common area', 'Common areas');

  const RoomType(this.label, this.lowerLabel, this.pluralLabel);
  final String label;
  final String lowerLabel;
  final String pluralLabel;
}

enum OccupancyMode {
  single('Single'),
  shared('Shared'),
  communal('Communal');

  const OccupancyMode(this.label);
  final String label;
}

enum NotificationType { nudge, statusChange, roomAssigned }

enum IssueEventType { reported, statusChanged, priorityChanged, noteAdded, nudged }

enum IssueSort {
  mostNudged('Most nudged', 'Issues students keep chasing first'),
  oldest('Oldest first', 'Longest waiting at the top'),
  newest('Newest first', null);

  const IssueSort(this.label, this.description);
  final String label;
  final String? description;
}
