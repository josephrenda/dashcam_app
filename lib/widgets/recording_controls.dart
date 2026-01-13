import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/incident_report_screen.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Report incident button (if authenticated)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isAuthenticated) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: _buildSecondaryButton(
                    icon: Icons.report,
                    label: 'Report',
                    onTap: () => _navigateToLastClip(context),
                    color: Colors.orange,
                  ),
                );
              },
            ),

            // Save clip button
            GestureDetector(
              onTap: () => _saveClip(context, cameraProvider),
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
          ],
        );
      },
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveClip(BuildContext context, CameraProvider provider) async {
    try {
      final clip = await provider.saveClip();

      if (clip != null && context.mounted) {
        final authProvider = context.read<AuthProvider>();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clip saved! Total clips: ${provider.clipCount}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
            action: authProvider.isAuthenticated
                ? SnackBarAction(
                    label: 'Report',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IncidentReportScreen(clip: clip),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save clip: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToLastClip(BuildContext context) {
    // This would ideally get the last saved clip from database
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save a clip first, then tap "Report" on the notification'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
