# Quick Start Guide

## Running the App

### 1. Install Dependencies
```bash
cd /mnt/d/AndroidProjects/dashcam_app
flutter pub get
```

### 2. Connect Device or Start Emulator
```bash
# List connected devices
flutter devices

# Or start an emulator
flutter emulators
flutter emulators --launch <emulator_id>
```

### 3. Run the App
```bash
# Development mode
flutter run

# Release mode (optimized)
flutter run --release

# Specific device
flutter run -d <device_id>
```

## Testing Features

### ✅ Available Now (No Backend)

**Camera Recording**
1. Launch app
2. Grant camera, microphone, and location permissions
3. Circular buffer starts automatically
4. See "RECORDING" indicator at top

**Display Modes**
1. Tap "Cam" for full-screen camera
2. Tap "Split" for camera + GPS view
3. Tap "GPS" for navigation mode

**Save Clips**
1. Tap large red button at bottom
2. See green success message
3. Clip counter updates in top-right

**GPS Tracking**
1. In Split or GPS mode
2. See current coordinates displayed
3. Saved clips include GPS data

### ⏳ Requires Backend Setup

**Authentication**
```dart
// Configure backend URL first
// lib/config/app_config.dart
static const String baseUrl = 'https://your-server.com/api/v1';

// Then use AuthProvider
final authProvider = context.read<AuthProvider>();
await authProvider.login(email, password);
```

**Incident Reporting**
```dart
final incident = IncidentModel(
  type: IncidentType.crash,
  latitude: position.latitude,
  longitude: position.longitude,
  timestamp: DateTime.now(),
  userId: currentUser.id,
);

await incidentProvider.reportIncident(incident, videoPath);
```

## Common Issues

### Permission Denied
**Problem**: App crashes or shows permission error  
**Solution**: 
```bash
# Android: Reinstall to trigger permission prompts
flutter clean
flutter run

# iOS: Check Info.plist has all usage descriptions
```

### Camera Not Initializing
**Problem**: Black screen or "No camera found"  
**Solution**:
- Ensure physical device has camera
- Check camera isn't used by another app
- Restart device

### Location Not Working
**Problem**: GPS coordinates show "Getting location..."  
**Solution**:
- Enable location services on device
- Grant location permission to app
- For emulator: Set mock location in settings

### Build Errors
**Problem**: Compilation fails  
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

## Project Commands

### Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split per ABI (smaller size)
flutter build apk --split-per-abi
```

### Build iOS
```bash
flutter build ios --release
```

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

### Run Tests
```bash
flutter test
```

## Development Workflow

### 1. Make Changes
Edit files in `lib/` directory

### 2. Hot Reload
Press `r` in terminal running `flutter run`  
Or press hot reload button in IDE

### 3. Hot Restart
Press `R` for full restart with state reset

### 4. Check Logs
```bash
# View logs
flutter logs

# Or with filtering
flutter logs | grep "YourTag"
```

## Next Implementation Steps

### Enable Voice Commands
In `lib/screens/home_screen.dart`:
```dart
import '../services/voice_command_service.dart';

@override
void initState() {
  super.initState();
  _initVoiceCommands();
}

void _initVoiceCommands() async {
  await VoiceCommandService.instance.initialize();
  await VoiceCommandService.instance.startListening(
    onCommand: (trigger) {
      final cameraProvider = context.read<CameraProvider>();
      cameraProvider.saveClip();
    },
  );
}
```

### Add Map Display
In `lib/widgets/camera_view.dart`, replace placeholder with:
```dart
import 'package:flutter_map/flutter_map.dart';

Widget _buildMapWidget(CameraProvider provider) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(
        provider.currentPosition?.latitude ?? 0,
        provider.currentPosition?.longitude ?? 0,
      ),
      zoom: 15,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
    ],
  );
}
```

### Create Incident Reporting Screen
```dart
// lib/screens/incident_report_screen.dart
class IncidentReportScreen extends StatelessWidget {
  final ClipModel clip;
  
  // Add form to select incident type
  // Add description field
  // Submit to IncidentProvider
}
```

## Backend Setup

### 1. Deploy Backend
Follow backend deployment guide in design document

### 2. Update Configuration
```dart
// lib/config/app_config.dart
static const String baseUrl = 'https://your-actual-api.com/api/v1';
static const String osrmBaseUrl = 'http://your-vps-ip:5000';
```

### 3. Test Endpoints
```bash
# Test from device/emulator
curl https://your-actual-api.com/api/v1/health
```

## Debugging

### Enable Verbose Logging
```bash
flutter run --verbose
```

### Check Device Logs
```bash
# Android
adb logcat | grep flutter

# iOS
flutter logs
```

### Inspect Database
```bash
# Android - pull database file
adb pull /data/data/com.example.dashcam_app/databases/dashcam.db

# Use SQLite browser to inspect
sqlite3 dashcam.db
```

## Performance Optimization

### Profile Performance
```bash
flutter run --profile
flutter run --trace-startup
```

### Reduce APK Size
```bash
flutter build apk --split-per-abi --target-platform android-arm64
```

### Check Memory
In DevTools:
1. Run `flutter run`
2. Press `v` to open DevTools
3. Navigate to Memory tab

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Camera Plugin Guide](https://pub.dev/packages/camera)
- [Provider State Management](https://pub.dev/packages/provider)
- [Design Document](./DESIGN_DOCUMENT.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)

## Support

For issues:
1. Check this guide
2. Review implementation summary
3. Check Flutter logs
4. Review relevant service files in `lib/services/`
