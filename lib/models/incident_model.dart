import 'package:uuid/uuid.dart';

enum IncidentType {
  crash,
  police,
  roadRage,
  hazard,
  other,
}

class IncidentModel {
  final String id;
  final IncidentType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? description;
  final String? videoPath;
  final double? speed;
  final double? heading;
  final String userId;
  final String status;

  IncidentModel({
    String? id,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.description,
    this.videoPath,
    this.speed,
    this.heading,
    required this.userId,
    this.status = 'pending',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'videoPath': videoPath,
      'speed': speed,
      'heading': heading,
      'userId': userId,
      'status': status,
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map) {
    return IncidentModel(
      id: map['id'] ?? map['incident_id'],
      type: IncidentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => IncidentType.other,
      ),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'],
      videoPath: map['videoPath'] ?? map['video_path'],
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      userId: map['userId'] ?? map['user_id'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'speed': speed,
      'heading': heading,
    };
  }
}
