import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';

class VideoBufferService {
  static final VideoBufferService instance = VideoBufferService._();
  VideoBufferService._();

  final List<String> _bufferSegments = [];
  final int _segmentDuration = AppConfig.segmentDurationSeconds;
  int _bufferDuration = AppConfig.circularBufferDefaultSeconds;
  Directory? _bufferDirectory;

  CameraController? _controller;
  bool _isRecording = false;
  DateTime? _segmentStartTime;

  Future<void> initialize(CameraController controller) async {
    _controller = controller;
    _bufferDirectory = await _getBufferDirectory();
    await _clearOldSegments();
  }

  Future<Directory> _getBufferDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final bufferDir = Directory('${appDir.path}/buffer');
    if (!await bufferDir.exists()) {
      await bufferDir.create(recursive: true);
    }
    return bufferDir;
  }

  Future<void> _clearOldSegments() async {
    if (_bufferDirectory == null) return;
    
    final files = _bufferDirectory!.listSync();
    for (var file in files) {
      if (file is File) {
        await file.delete();
      }
    }
    _bufferSegments.clear();
    await DatabaseService.instance.clearBufferSegments();
  }

  Future<void> startCircularRecording() async {
    if (_controller == null || _isRecording) return;
    await _recordNextSegment();
  }

  Future<void> _recordNextSegment() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      _segmentStartTime = DateTime.now();
      final timestamp = _segmentStartTime!.millisecondsSinceEpoch;
      final segmentPath = '${_bufferDirectory!.path}/segment_$timestamp.mp4';

      await _controller!.startVideoRecording();
      _isRecording = true;

      // Schedule next segment
      await Future.delayed(Duration(seconds: _segmentDuration));
      
      if (_isRecording) {
        await _stopAndSaveSegment(segmentPath);
        await _recordNextSegment();
      }
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to record segment: $e');
    }
  }

  Future<void> _stopAndSaveSegment(String targetPath) async {
    if (_controller == null || !_isRecording) return;

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move to buffer directory
      final targetFile = File(targetPath);
      await File(file.path).copy(targetFile.path);
      
      final fileSize = await targetFile.length();
      
      // Add to buffer
      _bufferSegments.add(targetPath);
      
      await DatabaseService.instance.insertBufferSegment({
        'filePath': targetPath,
        'timestamp': DateTime.now().toIso8601String(),
        'durationSeconds': _segmentDuration,
        'fileSizeBytes': fileSize,
      });

      // Manage buffer size
      await _manageBufferSize();
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to save segment: $e');
    }
  }

  Future<void> _manageBufferSize() async {
    final maxSegments = (_bufferDuration / _segmentDuration).ceil();
    
    while (_bufferSegments.length > maxSegments) {
      final oldestSegment = _bufferSegments.removeAt(0);
      
      // Delete file
      final file = File(oldestSegment);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete from database
      await DatabaseService.instance.deleteOldestBufferSegment();
    }
  }

  Future<String?> saveCurrentBuffer({
    double? latitude,
    double? longitude,
  }) async {
    if (_bufferSegments.isEmpty) return null;

    try {
      final clipsDir = await _getClipsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final clipPath = '${clipsDir.path}/clip_$timestamp.mp4';

      // For simplicity, copy the most recent segment
      // In production, merge all segments using FFmpeg
      final lastSegment = _bufferSegments.last;
      await File(lastSegment).copy(clipPath);

      return clipPath;
    } catch (e) {
      throw Exception('Failed to save buffer: $e');
    }
  }

  Future<Directory> _getClipsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final clipsDir = Directory('${appDir.path}/clips');
    if (!await clipsDir.exists()) {
      await clipsDir.create(recursive: true);
    }
    return clipsDir;
  }

  Future<void> stopRecording() async {
    if (_controller == null || !_isRecording) return;
    
    try {
      await _controller!.stopVideoRecording();
      _isRecording = false;
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  void setBufferDuration(int seconds) {
    if (seconds >= AppConfig.circularBufferMinSeconds &&
        seconds <= AppConfig.circularBufferMaxSeconds) {
      _bufferDuration = seconds;
    }
  }

  int get currentBufferDuration => _bufferDuration;
  int get segmentCount => _bufferSegments.length;
  bool get isRecording => _isRecording;
}
