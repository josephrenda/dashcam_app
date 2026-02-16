# Debug Guide for DashCam App

## Overview
This guide explains the debug features added to help diagnose the blank screen issue on Android devices.

## Debug Features Added

### 1. **Debug Overlay (Yellow Bug Icon)**
When the app runs, you'll see a yellow bug icon in the top-right corner. Tap it to show/hide the debug overlay.

The debug overlay shows:
- Real-time log of initialization steps
- Permission status
- Camera initialization progress
- Any errors that occur
- Quick retry buttons

### 2. **Console Debug Logging**
All major steps now log to the console with emoji prefixes for easy identification:
- 🔍 General debug messages
- ✅ Successful operations
- ❌ Errors/failures
- 📷 Camera operations
- 📽️ Video buffer operations
- 📍 Location operations
- 🎤 Voice command operations
- ⏱️ Timing/scheduling
- ⚠️ Warnings
- 🔴 Recording status

### 3. **Error Dialogs**
If camera initialization fails, a detailed error dialog appears showing:
- Error message
- Full stack trace
- Retry button
- Close button

### 4. **Startup Diagnostics**
The app now logs:
- Number of available cameras
- Each camera's name and direction
- Permission request results
- Each initialization step

## How to Debug the Blank Screen Issue

### Step 1: Install and Run
```bash
flutter clean
flutter pub get
flutter build apk
# Install on your device
```

### Step 2: Check the Debug Overlay
1. When the app starts, look for the yellow bug icon in the top-right
2. Tap it to open the debug overlay
3. Read through the log messages to see where the initialization stops

### Step 3: Check LogCat (Android Studio)
```bash
# Or use command line
adb logcat | grep -i "DEBUG\|ERROR\|Exception"
```

Look for messages starting with:
- `🔍 DEBUG:`
- `📷 CameraProvider`
- `📽️ VideoBufferService`

### Step 4: Common Issues and Solutions

#### Issue: "No cameras available"
**Solution:** 
- Check camera permissions in device settings
- Verify AndroidManifest.xml has camera permissions
- Try a different device

#### Issue: "Permissions denied"
**Solution:**
- Tap "Open Settings" in the permission dialog
- Manually grant Camera, Microphone, and Location permissions
- Restart the app

#### Issue: "Camera initialization failed"
**Solution:**
- Check the full error in the debug dialog
- Try tapping "Retry Initialization"
- Check if another app is using the camera
- Restart the device

#### Issue: Shows "Initializing camera..." forever
**Solution:**
- This means the app is stuck waiting for initialization
- Check the debug overlay for specific errors
- Look at LogCat for exceptions
- Try the "Retry Camera" button in the debug overlay

### Step 5: Permission Verification
The app requires these permissions:
- ✅ CAMERA
- ✅ RECORD_AUDIO
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ INTERNET
- ✅ WRITE_EXTERNAL_STORAGE (for Android < 10)
- ✅ READ_EXTERNAL_STORAGE

Check them in: **Settings > Apps > DashCam App > Permissions**

## Debug Log Interpretation

### Successful Initialization Flow:
```
App Started
initState called
Requesting permissions...
Camera permission: PermissionStatus.granted
Microphone permission: PermissionStatus.granted
Location permission: PermissionStatus.granted
✅ All permissions granted!
Starting camera initialization...
Available cameras: 2
Calling cameraProvider.initialize()...
📷 CameraProvider.initialize() called
📷 Number of cameras: 2
📷 Creating CameraController for Camera 0
📷 Initializing controller...
✅ Controller initialized successfully
📽️ VideoBufferService.initialize() called
📽️ Getting buffer directory...
📽️ Buffer directory: /data/user/0/.../files/buffer
📽️ Clearing old segments...
✅ VideoBufferService initialized successfully
📷 Starting recording...
📽️ startCircularRecording() called
📽️ Starting first segment...
🔴 Starting video recording to: .../segment_xxx.mp4
✅ Video recording started
✅ Camera initialized successfully!
Camera initialized, showing UI
```

### Failed Initialization Example:
```
App Started
initState called
Requesting permissions...
Camera permission: PermissionStatus.denied
❌ Permissions denied!
```

## Testing Display Modes

Once the camera initializes successfully, test the three display modes:
1. **Cam Only** - Shows only camera feed
2. **Split** - Shows camera feed on top, GPS map on bottom
3. **GPS Only** - Shows only the GPS map with incident markers

Tap the buttons at the top to switch between modes.

## Additional Debugging Tools

### Check Available Cameras
Run this command to see what cameras the device reports:
```dart
flutter run --release
# Then check the logcat output for "Successfully loaded N cameras"
```

### Test on Different Devices
If possible, test on:
- Different Android versions (API 21+)
- Different manufacturers
- Devices with different camera configurations

## Reporting Issues

When reporting issues, please include:
1. **Debug overlay log** (take a screenshot)
2. **LogCat output** (filter with "DEBUG")
3. **Device information** (model, Android version)
4. **Exact error message** from error dialogs
5. **Steps to reproduce**

## Quick Fixes to Try

1. **Restart the app**
2. **Clear app data**: Settings > Apps > DashCam App > Storage > Clear Data
3. **Reinstall the app**
4. **Restart the device**
5. **Check for system camera app issues** (can the default camera app work?)
6. **Close other camera-using apps**

## Development Mode

For even more detailed logging during development:
```bash
# Run in debug mode with verbose logging
flutter run -v
```

## Next Steps

Based on what you see in the debug overlay and logs:
- If permissions are the issue: Fix permission handling
- If camera fails to initialize: Check camera plugin compatibility
- If video buffer fails: Check storage permissions and space
- If UI doesn't show: Check widget rendering logic

The debug overlay should give you enough information to identify exactly where the initialization is failing!
