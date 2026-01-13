import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/camera_provider.dart';
import '../providers/incident_provider.dart';
import '../config/app_config.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        final controller = cameraProvider.controller;
        final displayMode = cameraProvider.displayMode;

        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        switch (displayMode) {
          case DisplayMode.webcamOnly:
            return _buildWebcamView(controller, cameraProvider);
          case DisplayMode.split:
            return _buildSplitView(controller, cameraProvider);
          case DisplayMode.gpsOnly:
            return _buildGPSView(cameraProvider);
        }
      },
    );
  }

  Widget _buildWebcamView(CameraController controller, CameraProvider provider) {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(controller),
        ),
        _buildRecordingIndicator(provider),
        _buildClipCounter(provider),
      ],
    );
  }

  Widget _buildSplitView(CameraController controller, CameraProvider provider) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              CameraPreview(controller),
              _buildRecordingIndicator(provider),
            ],
          ),
        ),
        Expanded(
          child: _buildMapWidget(provider),
        ),
      ],
    );
  }

  Widget _buildGPSView(CameraProvider provider) {
    return _buildMapWidget(provider);
  }

  Widget _buildMapWidget(CameraProvider provider) {
    return Consumer<IncidentProvider>(
      builder: (context, incidentProvider, child) {
        final position = provider.currentPosition;
        final center = position != null
            ? LatLng(position.latitude, position.longitude)
            : LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);

        return FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: AppConfig.defaultZoom,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.dashcam_app',
            ),
            // Incident markers
            MarkerLayer(
              markers: [
                // Current position marker
                if (position != null)
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                // Nearby incident markers
                ...incidentProvider.nearbyIncidents.map((incident) {
                  return Marker(
                    point: LatLng(incident.latitude, incident.longitude),
                    width: 30,
                    height: 30,
                    child: Icon(
                      _getIncidentIcon(incident.type.name),
                      color: _getIncidentColor(incident.type.name),
                      size: 30,
                    ),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  IconData _getIncidentIcon(String type) {
    switch (type) {
      case 'crash':
        return Icons.car_crash;
      case 'police':
        return Icons.local_police;
      case 'roadRage':
        return Icons.warning;
      case 'hazard':
        return Icons.warning_amber;
      default:
        return Icons.report_problem;
    }
  }

  Color _getIncidentColor(String type) {
    switch (type) {
      case 'crash':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'roadRage':
        return Colors.orange;
      case 'hazard':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecordingIndicator(CameraProvider provider) {
    if (!provider.isRecording) return const SizedBox.shrink();

    return Positioned(
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
              Text(
                'RECORDING',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClipCounter(CameraProvider provider) {
    return Positioned(
      top: 50,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(Icons.video_library, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              '${provider.clipCount}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'clips',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
