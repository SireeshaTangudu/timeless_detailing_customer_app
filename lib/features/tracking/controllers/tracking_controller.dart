import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/core/network/mock_odoo_service.dart';
import 'package:timeless_detailing_customer_app/features/bookings/models/booking_model.dart';
import 'package:timeless_detailing_customer_app/features/bookings/controllers/bookings_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

class TrackingController extends ChangeNotifier {
  final BaseOdooService _odooService;
  final BookingsController _bookingsController;

  Booking? _trackedBooking;
  List<ProjectModel> _projects = [];
  Map<int, List<ProjectTaskModel>> _projectTasksMap = {};
  bool _isLoading = false;

  TrackingController(this._odooService, this._bookingsController);

  Booking? get trackedBooking => _trackedBooking;
  List<ProjectModel> get projects => _projects;
  Map<int, List<ProjectTaskModel>> get projectTasksMap => _projectTasksMap;
  List<ProjectTaskModel> get allTasks => _projectTasksMap.values.expand((tasks) => tasks).toList();
  bool get isLoading => _isLoading;

  Map<int, List<ProjectTaskTypeModel>> _projectTaskTypesMap = {};

  Map<int, List<ProjectTaskTypeModel>> get projectTaskTypesMap => _projectTaskTypesMap;

  /// Fetches tracking status including live booking, active projects (Endpoint 8), project tasks and task types
  Future<void> fetchTrackingStatus(String bookingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _odooService.getLiveTrackingBooking(bookingId),
        _odooService.getProjects(),
      ]);
      _trackedBooking = results[0] as Booking?;
      _projects = (results[1] as List<ProjectModel>?) ?? [];

      _projectTasksMap = {};
      _projectTaskTypesMap = {};
      for (final project in _projects) {
        try {
          final tasks = await _odooService.getProjectTasks(project.id);
          _projectTasksMap[project.id] = tasks;
        } catch (_) {}

        try {
          final types = await _odooService.getProjectTaskTypes(project.id);
          _projectTaskTypesMap[project.id] = types;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error fetching tracking status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simulation method: Advances the status of the booking in mock database
  // to allow the user to preview how Odoo status transitions affect the client app.
  void simulateNextStatusStep() {
    if (_trackedBooking == null) return;
    if (_odooService is MockOdooService) {
      BookingStatus nextStatus;
      switch (_trackedBooking!.status) {
        case BookingStatus.confirmed:
          nextStatus = BookingStatus.received;
          break;
        case BookingStatus.received:
          nextStatus = BookingStatus.inProgress;
          break;
        case BookingStatus.inProgress:
          nextStatus = BookingStatus.ready;
          break;
        case BookingStatus.ready:
          nextStatus = BookingStatus.completed;
          break;
        case BookingStatus.completed:
          nextStatus = BookingStatus.confirmed; // reset cycle for loop testing
          break;
      }
      _odooService.updateMockBookingStatus(_trackedBooking!.id, nextStatus);
      
      // Reload states in both controllers
      _bookingsController.loadBookings();
      fetchTrackingStatus(_trackedBooking!.id);
    }
  }
}
