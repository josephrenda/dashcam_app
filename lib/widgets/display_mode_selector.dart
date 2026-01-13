import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';

class DisplayModeSelector extends StatelessWidget {
  const DisplayModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton(
              context,
              icon: Icons.videocam,
              label: 'Cam',
              isSelected: cameraProvider.displayMode == DisplayMode.webcamOnly,
              onTap: () => cameraProvider.setDisplayMode(DisplayMode.webcamOnly),
            ),
            const SizedBox(width: 8),
            _buildModeButton(
              context,
              icon: Icons.splitscreen,
              label: 'Split',
              isSelected: cameraProvider.displayMode == DisplayMode.split,
              onTap: () => cameraProvider.setDisplayMode(DisplayMode.split),
            ),
            const SizedBox(width: 8),
            _buildModeButton(
              context,
              icon: Icons.map,
              label: 'GPS',
              isSelected: cameraProvider.displayMode == DisplayMode.gpsOnly,
              onTap: () => cameraProvider.setDisplayMode(DisplayMode.gpsOnly),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red
              : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
