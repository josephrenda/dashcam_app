import 'package:uuid/uuid.dart';

enum ClipStatus {
  recording,
  saved,
  uploaded,
  failed,
}

class ClipModel {
  final String id;
  final String filePath;
  final DateTime timestamp;
  final int durationSeconds;
  final int fileSizeBytes;
  final double? latitude;
  final double? longitude;
  final ClipStatus status;
  final String? incidentId;

  ClipModel({
    String? id,
    required this.filePath,
    required this.timestamp,
    this.durationSeconds = 0,
    this.fileSizeBytes = 0,
    this.latitude,
    this.longitude,
    this.status = ClipStatus.saved,
    this.incidentId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'incidentId': incidentId,
    };
  }

  factory ClipModel.fromMap(Map<String, dynamic> map) {
    return ClipModel(
      id: map['id'],
      filePath: map['filePath'],
      timestamp: DateTime.parse(map['timestamp']),
      durationSeconds: map['durationSeconds'] ?? 0,
      fileSizeBytes: map['fileSizeBytes'] ?? 0,
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: ClipStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClipStatus.saved,
      ),
      incidentId: map['incidentId'],
    );
  }

  ClipModel copyWith({
    String? filePath,
    DateTime? timestamp,
    int? durationSeconds,
    int? fileSizeBytes,
    double? latitude,
    double? longitude,
    ClipStatus? status,
    String? incidentId,
  }) {
    return ClipModel(
      id: id,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      incidentId: incidentId ?? this.incidentId,
    );
  }
}
