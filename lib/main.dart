import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error: $e');
  }
  
  runApp(const DashCamApp());
}

class DashCamApp extends StatelessWidget {
  const DashCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashCam App',
      theme: ThemeData. dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _permissionsGranted = false;
  String?  _lastVideoPath;
  int _clipCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera. request();
    final micStatus = await Permission.microphone.request();
    final locationStatus = await Permission.location.request();
    final storageStatus = await Permission.storage. request();
    
    if (cameraStatus.isGranted && micStatus. isGranted) {
      setState(() => _permissionsGranted = true);
      _initializeCamera();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text('This app needs Camera, Microphone, and Storage permissions to work. '),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissions();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      _showError('No camera found on this device');
      return;
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset. high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        _startRecording();
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller! .value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  Future<void> _saveClip() async {
    if (_controller == null || !_isRecording) return;

    try {
      final file = await _controller!.stopVideoRecording();
      
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final clipPath = '${directory.path}/clip_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Copy to permanent storage
      await File(file.path).copy(clipPath);
      
      setState(() {
        _isRecording = false;
        _lastVideoPath = clipPath;
        _clipCount++;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clip #$_clipCount saved!\nPath: $clipPath'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _showClipInfo(clipPath),
            ),
          ),
        );
      }
      
      // Restart recording
      await Future.delayed(const Duration(milliseconds: 500));
      _startRecording();
      
    } catch (e) {
      _showError('Error saving clip: $e');
      setState(() => _isRecording = false);
      _startRecording();
    }
  }

  void _showClipInfo(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clip Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total clips saved: $_clipCount'),
            const SizedBox(height: 8),
            Text('Location:\n$path', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Text('You can find your clips in the app\'s documents folder.', 
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (! mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (! _permissionsGranted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('Camera permissions required', 
                style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permissions'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Recording Indicator
          if (_isRecording)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('RECORDING', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                    ],
                  ),
                ),
              ),
            ),
          
          // Clip Counter
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black. withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.video_library, color: Colors.white),
                  const SizedBox(height: 4),
                  Text('$_clipCount', 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                  const Text('clips', 
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
          
          // Save Clip Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _saveClip,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.save, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}