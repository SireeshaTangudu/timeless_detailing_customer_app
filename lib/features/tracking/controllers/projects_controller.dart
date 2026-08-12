import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

class ProjectsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<ProjectModel> _projects = [];
  final Map<int, List<ProjectTaskModel>> _projectTasks = {};
  bool _isLoading = false;
  String? _errorMessage;

  ProjectsController(this._odooService) {
    loadProjects();
  }

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Endpoint 8: Get All Projects (`project.project/web_search_read`)
  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _odooService.getProjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch projects.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Endpoint 9: Get Project Tasks (`project.task/web_search_read`)
  Future<List<ProjectTaskModel>> loadTasksForProject(int projectId) async {
    if (_projectTasks.containsKey(projectId)) {
      return _projectTasks[projectId]!;
    }

    try {
      final tasks = await _odooService.getProjectTasks(projectId);
      _projectTasks[projectId] = tasks;
      notifyListeners();
      return tasks;
    } catch (e) {
      return [];
    }
  }
}
