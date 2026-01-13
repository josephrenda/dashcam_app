import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';

class VoiceStatusIndicator extends StatelessWidget {
  const VoiceStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        if (!cameraProvider.isVoiceEnabled) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => cameraProvider.toggleVoiceCommands(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cameraProvider.isVoiceListening
                      ? Icons.mic
                      : Icons.mic_off,
                  color: cameraProvider.isVoiceListening
                      ? Colors.green
                      : Colors.white54,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  cameraProvider.isVoiceListening ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: cameraProvider.isVoiceListening
                        ? Colors.green
                        : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
