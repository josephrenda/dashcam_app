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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
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
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    final locationStatus = await Permission.location.request();

    if (cameraStatus.isGranted && micStatus.isGranted && locationStatus.isGranted) {
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
    if (_isInitializing) return;
    
    setState(() => _isInitializing = true);

    try {
      final cameraProvider = context.read<CameraProvider>();
      await cameraProvider.initialize(cameras);
    } catch (e) {
      _showError('Failed to initialize: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
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
    if (!_permissionsGranted) {
      return Scaffold(
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
      );
    }

    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        if (!cameraProvider.isInitialized) {
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
