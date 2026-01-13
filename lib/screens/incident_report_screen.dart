import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clip_model.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../providers/incident_provider.dart';
import '../providers/auth_provider.dart';

class IncidentReportScreen extends StatefulWidget {
  final ClipModel clip;

  const IncidentReportScreen({
    super.key,
    required this.clip,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  IncidentType _selectedType = IncidentType.other;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      _showError('Please login to report incidents');
      return;
    }

    if (widget.clip.latitude == null || widget.clip.longitude == null) {
      _showError('GPS coordinates not available for this clip');
      return;
    }

    setState(() => _isSubmitting = true);

    final incident = IncidentModel(
      type: _selectedType,
      latitude: widget.clip.latitude!,
      longitude: widget.clip.longitude!,
      timestamp: widget.clip.timestamp,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      videoPath: widget.clip.filePath,
      userId: authProvider.currentUser!.id,
    );

    final incidentProvider = context.read<IncidentProvider>();
    final success = await incidentProvider.reportIncident(
      incident,
      widget.clip.filePath,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(incidentProvider.errorMessage ?? 'Failed to report incident');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clip info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clip Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      _formatDateTime(widget.clip.timestamp),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      'Location',
                      widget.clip.latitude != null
                          ? '${widget.clip.latitude!.toStringAsFixed(4)}, '
                              '${widget.clip.longitude!.toStringAsFixed(4)}'
                          : 'Not available',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Incident type selector
            const Text(
              'Incident Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentType.values.map((type) {
                return ChoiceChip(
                  label: Text(_getIncidentLabel(type)),
                  avatar: Icon(
                    _getIncidentIcon(type),
                    size: 18,
                  ),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: _getIncidentColor(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Add details about the incident...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your clip will be uploaded and shared with the community to help keep roads safe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getIncidentLabel(IncidentType type) {
    switch (type) {
      case IncidentType.crash:
        return 'Crash';
      case IncidentType.police:
        return 'Police';
      case IncidentType.roadRage:
        return 'Road Rage';
      case IncidentType.hazard:
        return 'Hazard';
      case IncidentType.other:
        return 'Other';
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.crash:
        return Icons.car_crash;
      case IncidentType.police:
        return Icons.local_police;
      case IncidentType.roadRage:
        return Icons.warning;
      case IncidentType.hazard:
        return Icons.warning_amber;
      case IncidentType.other:
        return Icons.report_problem;
    }
  }

  Color _getIncidentColor(IncidentType type) {
    switch (type) {
      case IncidentType.crash:
        return Colors.red;
      case IncidentType.police:
        return Colors.blue;
      case IncidentType.roadRage:
        return Colors.orange;
      case IncidentType.hazard:
        return Colors.yellow;
      case IncidentType.other:
        return Colors.grey;
    }
  }
}
