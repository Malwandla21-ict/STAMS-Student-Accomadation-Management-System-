import 'enums.dart';
import 'user.dart';

class Property {
  const Property({
    required this.id,
    required this.name,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.postalCode,
    this.roomCount = 0,
    this.bedsFilled = 0,
    this.bedsTotal = 0,
    this.openIssueCount = 0,
    this.openIssueNudges = 0,
    this.createdAt,
    this.rooms,
  });

  final int id;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;
  final int roomCount;
  final int bedsFilled;
  final int bedsTotal;
  final int openIssueCount;
  final int openIssueNudges;
  final DateTime? createdAt;

  /// Only filled in on the single-property endpoint (L6).
  final List<Room>? rooms;

  String get shortAddress => '$addressLine1, $city $postalCode';

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        addressLine1: json['addressLine1'] as String,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String,
        postalCode: json['postalCode'] as String,
        roomCount: (json['roomCount'] as num? ?? 0).toInt(),
        bedsFilled: (json['bedsFilled'] as num? ?? 0).toInt(),
        bedsTotal: (json['bedsTotal'] as num? ?? 0).toInt(),
        openIssueCount: (json['openIssueCount'] as num? ?? 0).toInt(),
        openIssueNudges: (json['openIssueNudges'] as num? ?? 0).toInt(),
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
        rooms: (json['rooms'] as List?)?.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList(),
      );
}

/// Body for creating or editing a property (L7).
class PropertyInput {
  const PropertyInput({required this.name, required this.addressLine1, this.addressLine2, required this.city, required this.postalCode});

  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String postalCode;

  Map<String, dynamic> toJson() => {
        'name': name,
        'addressLine1': addressLine1,
        if (addressLine2 != null && addressLine2!.isNotEmpty) 'addressLine2': addressLine2,
        'city': city,
        'postalCode': postalCode,
      };
}

class Room {
  const Room({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.name,
    required this.type,
    required this.occupancyMode,
    this.capacity,
    this.occupied = 0,
    this.openIssueCount = 0,
    this.students = const [],
  });

  final int id;
  final int propertyId;
  final String propertyName;
  final String name;
  final RoomType type;
  final OccupancyMode occupancyMode;

  /// Null for communal rooms.
  final int? capacity;
  final int occupied;
  final int openIssueCount;
  final List<StudentSummary> students;

  bool get isCommunal => occupancyMode == OccupancyMode.communal;
  bool get isFull => !isCommunal && occupied >= (capacity ?? 0);
  int get freeBeds => isCommunal ? 0 : ((capacity ?? 0) - occupied).clamp(0, 99);

  /// "Shared bedroom", "Communal kitchen", "Single bedroom".
  String get description => '${occupancyMode.label} ${type.lowerLabel}';

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: (json['id'] as num).toInt(),
        propertyId: (json['propertyId'] as num).toInt(),
        propertyName: json['propertyName'] as String? ?? '',
        name: json['name'] as String,
        type: enumFromJson(RoomType.values, json['type']),
        occupancyMode: enumFromJson(OccupancyMode.values, json['occupancyMode']),
        capacity: (json['capacity'] as num?)?.toInt(),
        occupied: (json['occupied'] as num? ?? 0).toInt(),
        openIssueCount: (json['openIssueCount'] as num? ?? 0).toInt(),
        students: (json['students'] as List? ?? const [])
            .map((s) => StudentSummary.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Body for creating or editing a room (L9). Capacity is only sent for shared rooms.
class RoomInput {
  const RoomInput({required this.name, required this.type, required this.occupancyMode, this.capacity});

  final String name;
  final RoomType type;
  final OccupancyMode occupancyMode;
  final int? capacity;

  int? get effectiveCapacity => switch (occupancyMode) {
        OccupancyMode.single => 1,
        OccupancyMode.shared => capacity,
        OccupancyMode.communal => null,
      };

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': enumToJson(type),
        'occupancyMode': enumToJson(occupancyMode),
        if (occupancyMode == OccupancyMode.shared) 'capacity': capacity,
      };
}
