import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../providers/camera_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/recording_controls.dart';
import '../widgets/display_mode_selector.dart';
import '../widgets/voice_status_indicator.dart';
import '../screens/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = false;
  bool _isInitializing = false;
  String _debugLog = 'App Started\n';
  bool _showDebugOverlay = true;

  @override
  void initState() {
    super.initState();
    _addDebugLog('initState called');
    _requestPermissions();
  }

  void _addDebugLog(String message) {
    setState(() {
      _debugLog += '${DateTime.now().toIso8601String().substring(11, 19)}: $message\n';
    });
    debugPrint('🔍 DEBUG: $message');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch nearby incidents when authenticated
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated) {
      context.read<IncidentProvider>().fetchNearbyIncidents();
    }
  }

  Future<void> _requestPermissions() async {
    _addDebugLog('Requesting permissions...');
    
    final cameraStatus = await Permission.camera.request();
    _addDebugLog('Camera permission: $cameraStatus');
    
    final micStatus = await Permission.microphone.request();
    _addDebugLog('Microphone permission: $micStatus');
    
    final locationStatus = await Permission.location.request();
    _addDebugLog('Location permission: $locationStatus');

    if (cameraStatus.isGranted && micStatus.isGranted && locationStatus.isGranted) {
      _addDebugLog('✅ All permissions granted!');
      setState(() => _permissionsGranted = true);
      _initializeCamera();
    } else {
      _addDebugLog('❌ Permissions denied!');
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs Camera, Microphone, and Location permissions to work properly.',
        ),
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
    if (_isInitializing) {
      _addDebugLog('Already initializing, skipping...');
      return;
    }
    
    _addDebugLog('Starting camera initialization...');
    _addDebugLog('Available cameras: ${cameras.length}');
    setState(() => _isInitializing = true);

    try {
      final cameraProvider = context.read<CameraProvider>();
      _addDebugLog('Calling cameraProvider.initialize()...');
      await cameraProvider.initialize(cameras);
      _addDebugLog('✅ Camera initialized successfully!');
    } catch (e, stackTrace) {
      _addDebugLog('❌ Initialize error: $e');
      _showError('Failed to initialize: $e\n\nStackTrace: $stackTrace');
      _showDebugDialog('Camera Initialization Failed', e.toString(), stackTrace.toString());
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _showDebugDialog(String title, String error, String stackTrace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(error),
              SizedBox(height: 16),
              Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                stackTrace,
                style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeCamera();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_permissionsGranted)
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Camera permissions required',
                    style: TextStyle(fontSize: 18),
                  ),
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
          )
        else
          _buildMainContent(),
        
        // Debug overlay
        if (_showDebugOverlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DEBUG LOG',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _showDebugOverlay = false),
                      ),
                    ],
                  ),
                  Container(
                    height: 200,
                    child: SingleChildScrollView(
                      child: Text(
                        _debugLog,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _requestPermissions,
                        child: const Text('Check Permissions'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _initializeCamera,
                        child: const Text('Retry Camera'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        
        // Toggle debug button
        if (!_showDebugOverlay)
          Positioned(
            top: 40,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.yellow,
              onPressed: () => setState(() => _showDebugOverlay = true),
              child: const Icon(Icons.bug_report, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent() {

    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        if (!cameraProvider.isInitialized) {
          _addDebugLog('Waiting for camera to initialize...');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Initializing camera...'),
                  const SizedBox(height: 16),
                  Text(
                    'Available cameras: ${cameras.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _addDebugLog('Manual retry button pressed');
                      _initializeCamera();
                    },
                    child: const Text('Retry Initialization'),
                  ),
                ],
              ),
            ),
          );
        }

        _addDebugLog('Camera initialized, showing UI');
        return Scaffold(
          body: Stack(
            children: [
              const CameraView(),
              
              // Top bar with mode selector and menu
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: DisplayModeSelector()),
                    const SizedBox(width: 8),
                    _buildMenuButton(context),
                  ],
                ),
              ),
              
              const Positioned(
                top: 100,
                right: 16,
                child: VoiceStatusIndicator(),
              ),
              const Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: RecordingControls(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
          onSelected: (value) => _handleMenuSelection(context, value, authProvider),
          itemBuilder: (context) => [
            if (!authProvider.isAuthenticated)
              const PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 12),
                    Text('Login / Register'),
                  ],
                ),
              ),
            if (authProvider.isAuthenticated) ...[
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 12),
                    Text(authProvider.currentUser?.username ?? 'Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'my_incidents',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 12),
                    Text('My Incidents'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'refresh_incidents',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 12),
                  Text('Refresh Map'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(
    BuildContext context,
    String value,
    AuthProvider authProvider,
  ) {
    switch (value) {
      case 'login':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        break;
      case 'logout':
        authProvider.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        break;
      case 'my_incidents':
        context.read<IncidentProvider>().fetchMyIncidents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching your incidents...')),
        );
        break;
      case 'refresh_incidents':
        context.read<IncidentProvider>().fetchNearbyIncidents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshing nearby incidents...')),
        );
        break;
    }
  }
}
