import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final String makeModel;
  final String licensePlate;
  final String color;

  const Vehicle({
    required this.id,
    required this.makeModel,
    required this.licensePlate,
    required this.color,
  });
}

class DashboardController extends ChangeNotifier {
  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: 'vh_1',
      makeModel: 'Porsche 911 GT3 (992)',
      licensePlate: 'TIMELESS-1',
      color: 'Chalk Grey',
    ),
    const Vehicle(
      id: 'vh_2',
      makeModel: 'Tesla Model S Plaid',
      licensePlate: 'E-SPEED-9',
      color: 'Solid Black',
    ),
  ];

  List<Vehicle> get vehicles => _vehicles;

  void addVehicle(String makeModel, String licensePlate, String color) {
    final newVehicle = Vehicle(
      id: 'vh_${_vehicles.length + 1}',
      makeModel: makeModel,
      licensePlate: licensePlate,
      color: color,
    );
    _vehicles.add(newVehicle);
    notifyListeners();
  }

  void removeVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}
