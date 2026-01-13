# Dashcam App

A comprehensive Flutter dash camera app with GPS navigation and incident reporting capabilities.

## Features Implemented

### ✅ Core Architecture
- **Clean Architecture**: Organized into models, services, providers, screens, and widgets
- **State Management**: Provider pattern for reactive UI updates
- **Local Database**: SQLite for persistent storage of clips and incidents
- **Secure Storage**: Flutter secure storage for JWT tokens

### ✅ Camera & Recording
- **Circular Buffer Recording**: Continuous 10-second segments with configurable buffer (60-300s)
- **Three Display Modes**:
  - Webcam Only: Full-screen camera view
  - Split Mode: Camera + GPS map (50/50)
  - GPS Only: Full-screen navigation
- **Clip Management**: Save current buffer to permanent storage
- **Visual Indicators**: Recording status, clip counter

### ✅ Data Models
- **ClipModel**: Video clip metadata with GPS coordinates
- **IncidentModel**: Incident reports with type, location, and video
- **UserModel**: User authentication and profile data

### ✅ Services
- **DatabaseService**: SQLite operations for clips, incidents, and buffer segments
- **ApiService**: RESTful API client with JWT authentication
  - User registration/login/logout
  - Incident reporting with video upload
  - Fetch nearby incidents
  - Token refresh mechanism
- **LocationService**: GPS tracking and position streaming
- **VideoBufferService**: Circular buffer management with segment recording

### ✅ API Integration (Ready)
- JWT authentication flow
- Incident reporting endpoint
- Nearby incidents fetching
- User incident management
- All endpoints follow the design specification

### 🚧 In Progress
- Voice command support ("clip this")
- MapLibre integration for GPS visualization
- OSRM backend connection for navigation
- FFmpeg video merging (currently copies last segment)

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # App-wide configuration
├── models/
│   ├── clip_model.dart          # Video clip data model
│   ├── incident_model.dart      # Incident report model
│   └── user_model.dart          # User authentication model
├── services/
│   ├── api_service.dart         # REST API client
│   ├── database_service.dart    # SQLite database operations
│   ├── location_service.dart    # GPS tracking
│   └── video_buffer_service.dart # Circular buffer management
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── camera_provider.dart     # Camera & recording state
│   └── incident_provider.dart   # Incident reporting state
├── screens/
│   └── home_screen.dart         # Main app screen
├── widgets/
│   ├── camera_view.dart         # Camera display with modes
│   ├── display_mode_selector.dart # Mode switching UI
│   └── recording_controls.dart  # Recording action buttons
└── main.dart                     # App entry point
```

## Configuration

Edit `lib/config/app_config.dart` to set:
- Backend API URL
- OSRM server URL
- Video quality settings
- Buffer duration
- Incident reporting settings

## Dependencies

### Camera & Video
- `camera` - Camera access and recording
- `video_player` - Video playback
- `ffmpeg_kit_flutter` - Video processing

### Storage
- `path_provider` - File system paths
- `sqflite` - Local SQLite database
- `shared_preferences` - App settings
- `flutter_secure_storage` - Secure token storage

### Location & Maps
- `geolocator` - GPS positioning
- `flutter_map` - Map display
- `latlong2` - Coordinate utilities

### Networking
- `dio` - HTTP client for API calls

### State Management
- `provider` - Reactive state management

### Utilities
- `permission_handler` - Runtime permissions
- `uuid` - Unique ID generation
- `intl` - Date formatting
- `crypto` - Cryptographic operations

## Setup

1. **Install dependencies**:
```bash
flutter pub get
```

2. **Configure backend URL** in `lib/config/app_config.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com/api/v1';
```

3. **Android permissions** (already configured in manifest):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

4. **iOS permissions** (already configured in Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access needed for dashcam recording</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for audio recording</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location needed for GPS tracking</string>
```

## Usage

### Recording
1. App automatically starts circular buffer recording on launch
2. Buffer continuously records 10-second segments
3. Old segments are auto-deleted when buffer is full

### Saving Clips
1. Tap the red save button to capture current buffer
2. Clip is saved to permanent storage with GPS coordinates
3. Clip counter updates in top-right corner

### Display Modes
1. Tap mode buttons at top to switch views:
   - **Cam**: Full-screen camera
   - **Split**: Camera + GPS map
   - **GPS**: Full-screen navigation

### Incident Reporting (Backend Required)
1. Save a clip
2. Use incident reporting feature (to be added to UI)
3. Select incident type (crash, police, hazard, etc.)
4. Video uploads to server for processing

## Backend Integration

The app is ready to connect to a Python FastAPI backend with:
- JWT authentication
- Video upload with multipart/form-data
- Incident reporting
- Nearby incident fetching

See design document for backend specifications.

## Development Progress

**Phase 1**: ✅ Architecture & Structure  
**Phase 2**: ✅ Core Models & Services  
**Phase 3**: ✅ Circular Buffer (basic implementation)  
**Phase 4**: ✅ Camera & Recording (core features)  
**Phase 5**: 🚧 GPS & Navigation (location tracking ready)  
**Phase 6**: ✅ Backend Integration (services ready, needs testing)

## Next Steps

1. Implement voice command recognition
2. Integrate MapLibre for map visualization
3. Connect to OSRM for turn-by-turn navigation
4. Add FFmpeg video merging for complete buffer saves
5. Build incident reporting UI
6. Add settings screen
7. Implement background recording service
8. Add crash detection via accelerometer
9. Battery & thermal optimization

## Testing

To test without backend:
- All camera and recording features work offline
- Clips are saved to local database
- GPS coordinates are captured
- Backend calls will fail gracefully with error messages

## Notes

- Circular buffer currently copies last segment; full FFmpeg merge coming soon
- Map view is placeholder; MapLibre integration in progress
- Voice commands service ready but not integrated to UI yet
- Backend endpoints follow design specification exactly

## License

[Your License Here]
