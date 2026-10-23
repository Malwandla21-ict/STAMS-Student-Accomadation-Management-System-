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

  factory StudentHome.fromJson(Map<String, dynamic> json) => StudentHome(
        room: Room.fromJson(json['room'] as Map<String, dynamic>),
        propertyName: json['propertyName'] as String,
        landlordName: json['landlordName'] as String,
        roommates: (json['roommates'] as List? ?? const [])
            .map((s) => StudentSummary.fromJson(s as Map<String, dynamic>))
            .toList(),
        sharedSpaces: (json['sharedSpaces'] as List? ?? const [])
            .map((r) => Room.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}
