import 'enums.dart';

class AppUser {
  const AppUser({required this.id, required this.name, required this.email, required this.role, this.phone, this.createdAt});

  final int id;
  final String name;
  final String email;
  final Role role;
  final String? phone;
  final DateTime? createdAt;

  bool get isLandlord => role == Role.landlord;
  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initials => initialsOf(name);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: enumFromJson(Role.values, json['role']),
        phone: json['phone'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      );
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class StudentSummary {
  const StudentSummary({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  String get initials => initialsOf(name);

  factory StudentSummary.fromJson(Map<String, dynamic> json) => StudentSummary(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

enum Placement { notInARoom, inYourProperty, withAnotherLandlord }

/// One row in "Assign student" search (L10).
class StudentSearchResult {
  const StudentSearchResult({
    required this.id,
    required this.name,
    required this.email,
    required this.placement,
    this.currentRoomId,
    this.currentRoomName,
    this.currentPropertyName,
  });

  final int id;
  final String name;
  final String email;
  final Placement placement;
  final int? currentRoomId;
  final String? currentRoomName;
  final String? currentPropertyName;

  String get initials => initialsOf(name);

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) => StudentSearchResult(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        placement: enumFromJson(Placement.values, json['placement']),
        currentRoomId: (json['currentRoomId'] as num?)?.toInt(),
        currentRoomName: json['currentRoomName'] as String?,
        currentPropertyName: json['currentPropertyName'] as String?,
      );
}
