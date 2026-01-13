import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class IncidentProvider extends ChangeNotifier {
  List<IncidentModel> _nearbyIncidents = [];
  List<IncidentModel> _myIncidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<IncidentModel> get nearbyIncidents => _nearbyIncidents;
  List<IncidentModel> get myIncidents => _myIncidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNearbyIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      _nearbyIncidents = await ApiService.instance.getNearbyIncidents(
        position.latitude,
        position.longitude,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myIncidents = await ApiService.instance.getMyIncidents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportIncident(IncidentModel incident, String videoPath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService.instance.reportIncident(incident, videoPath);
      await fetchMyIncidents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncident(String incidentId) async {
    try {
      await ApiService.instance.deleteIncident(incidentId);
      _myIncidents.removeWhere((i) => i.id == incidentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
