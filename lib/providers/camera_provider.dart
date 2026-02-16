import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/video_buffer_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/voice_command_service.dart';
import '../models/clip_model.dart';
import 'package:geolocator/geolocator.dart';

enum DisplayMode { webcamOnly, split, gpsOnly }

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;
  DisplayMode _displayMode = DisplayMode.webcamOnly;
  Position? _currentPosition;
  int _clipCount = 0;
  bool _isVoiceEnabled = false;
  bool _isVoiceListening = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized; 
  bool get isRecording => _isRecording;
  DisplayMode get displayMode => _displayMode;
  Position? get currentPosition => _currentPosition;
  int get clipCount => _clipCount;
  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isVoiceListening => _isVoiceListening;

  Future<void> initialize(List<CameraDescription> cameras) async {
    debugPrint('📷 CameraProvider.initialize() called');
    debugPrint('📷 Number of cameras: ${cameras.length}');
    
    if (cameras.isEmpty) {
      debugPrint('❌ No cameras available!');
      throw Exception('No cameras available');
    }

    debugPrint('📷 Creating CameraController for ${cameras.first.name}');
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      debugPrint('📷 Initializing controller...');
      await _controller!.initialize();
      debugPrint('✅ Controller initialized successfully');
      
      debugPrint('📷 Initializing VideoBufferService...');
      await VideoBufferService.instance.initialize(_controller!);
      debugPrint('✅ VideoBufferService initialized');
      
      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ notifyListeners() called');
      
      // Start circular recording
      debugPrint('📷 Starting recording...');
      await startRecording();
      
      // Start location tracking
      debugPrint('📏 Starting location tracking...');
      _startLocationTracking();
      
      // Initialize voice commands
      debugPrint('🎤 Initializing voice commands...');
      await _initializeVoiceCommands();
      
      debugPrint('✅ Camera provider fully initialized!');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize camera: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeVoiceCommands() async {
    try {
      final hasPermission = await VoiceCommandService.instance.checkPermission();
      if (hasPermission) {
        _isVoiceEnabled = await VoiceCommandService.instance.initialize();
        if (_isVoiceEnabled) {
          await startVoiceListening();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Voice command initialization failed: $e');
    }
  }

  Future<void> startVoiceListening() async {
    if (!_isVoiceEnabled || _isVoiceListening) return;

    try {
      await VoiceCommandService.instance.startListening(
        onCommand: (trigger) async {
          debugPrint('Voice command detected: $trigger');
          await saveClip();
        },
      );
      _isVoiceListening = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start voice listening: $e');
    }
  }

  Future<void> stopVoiceListening() async {
    if (!_isVoiceListening) return;

    try {
      await VoiceCommandService.instance.stopListening();
      _isVoiceListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop voice listening: $e');
    }
  }

  void toggleVoiceCommands() async {
    if (_isVoiceListening) {
      await stopVoiceListening();
    } else {
      await startVoiceListening();
    }
  }

  void _startLocationTracking() {
    LocationService.instance.getPositionStream().listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Future<void> startRecording() async {
    if (_isRecording || !_isInitialized) {
      debugPrint('⚠️ Cannot start recording - isRecording: $_isRecording, isInitialized: $_isInitialized');
      return;
    }
    
    try {
      debugPrint('🔴 Starting circular recording...');
      await VideoBufferService.instance.startCircularRecording();
      _isRecording = true;
      notifyListeners();
      debugPrint('✅ Recording started successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to start recording: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<ClipModel?> saveClip() async {
    if (!_isRecording) return null;

    try {
      final clipPath = await VideoBufferService.instance.saveCurrentBuffer(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (clipPath == null) return null;

      final clip = ClipModel(
        filePath: clipPath,
        timestamp: DateTime.now(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        status: ClipStatus.saved,
      );

      await DatabaseService.instance.insertClip(clip);
      _clipCount++;
      notifyListeners();

      return clip;
    } catch (e) {
      throw Exception('Failed to save clip: $e');
    }
  }

  void setDisplayMode(DisplayMode mode) {
    _displayMode = mode;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await stopVoiceListening();
    VoiceCommandService.instance.dispose();
    await VideoBufferService.instance.stopRecording();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
  }
}
