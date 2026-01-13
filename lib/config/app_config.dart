class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://api.yourdomain.com/api/v1';
  
  // Video Recording Settings
  static const int circularBufferMinSeconds = 60;
  static const int circularBufferMaxSeconds = 300;
  static const int circularBufferDefaultSeconds = 120;
  static const int segmentDurationSeconds = 10;
  
  // Video Quality Settings
  static const int videoQualityHigh = 720;
  static const int videoQualityMedium = 480;
  static const int videoQualityLow = 360;
  
  // Storage Settings
  static const int maxStorageMB = 500;
  static const int maxVideoSizeMB = 100;
  
  // Map Settings
  static const String osrmBaseUrl = 'http://your-vps-ip:5000';
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 13.0;
  
  // Incident Reporting
  static const double nearbyIncidentRadiusKm = 5.0;
  static const int incidentTimeWindowHours = 24;
  
  // App Settings
  static const bool uploadOnWifiOnly = true;
  static const bool enableVoiceCommands = true;
  static const String voiceCommandTrigger = 'clip this';
}
