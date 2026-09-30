import 'property.dart';
import 'user.dart';

/// Everything the student home (S1) and report flow (S2) need:
/// their room, who they share it with, and the property's shared spaces.
class StudentHome {
  const StudentHome({
    required this.room,
    required this.propertyName,
    required this.landlordName,
    this.roommates = const [],
    this.sharedSpaces = const [],
  });

  final Room room;
  final String propertyName;
  final String landlordName;
  final List<StudentSummary> roommates;
  final List<Room> sharedSpaces;

  String get landlordFirstName => landlordName.split(' ').first;
}
