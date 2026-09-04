import 'package:flutter/material.dart';
import 'package:timeless_detailing_customer_app/core/network/odoo_client.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

class ProjectsController extends ChangeNotifier {
  final BaseOdooService _odooService;

  List<ProjectModel> _projects = [];
  List<ProjectStageModel> _projectStages = [];
  final Map<int, List<ProjectTaskModel>> _projectTasks = {};
  final Map<int, List<ProjectTaskTypeModel>> _projectTaskTypes = {};
  final Map<int, CustomerTaskStageProgressModel> _taskProgressMap = {};

  bool _isLoading = false;
  String? _errorMessage;

  ProjectsController(this._odooService) {
    loadProjects();
  }

  List<ProjectModel> get projects => _projects;
  List<ProjectStageModel> get projectStages => _projectStages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get All Projects (`project.project/web_search_read`)
  Future<void> loadProjects({int? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedProjects =
          await _odooService.getProjects(projectId: projectId);
      if (projectId != null && projectId > 0) {
        // If single project returned, merge into existing list or set as primary
        for (final p in fetchedProjects) {
          final idx = _projects.indexWhere((item) => item.id == p.id);
          if (idx >= 0) {
            _projects[idx] = p;
          } else {
            _projects.insert(0, p);
          }
        }
      } else {
        _projects = fetchedProjects;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch projects.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get Project Stage Definitions (`project.project.stage/web_search_read`)
  Future<List<ProjectStageModel>> loadProjectStages() async {
    if (_projectStages.isNotEmpty) return _projectStages;
    try {
      _projectStages = await _odooService.getProjectStages();
      notifyListeners();
      return _projectStages;
    } catch (e) {
      return [];
    }
  }

  /// Get Project Tasks (`project.task/web_search_read`)
  Future<List<ProjectTaskModel>> loadTasksForProject(int projectId) async {
    try {
      final tasks = await _odooService.getProjectTasks(projectId);
      _projectTasks[projectId] = tasks;
      notifyListeners();
      return tasks;
    } catch (e) {
      return _projectTasks[projectId] ?? [];
    }
  }

  /// Get Customer Task Stage Progress (`project.task/get_customer_stage_progress`)
  Future<CustomerTaskStageProgressModel?> loadTaskProgress(
      int taskId, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh && _taskProgressMap.containsKey(taskId)) {
      return _taskProgressMap[taskId];
    }

    try {
      final progress = await _odooService.getTaskStageProgress(taskId);
      if (progress != null) {
        _taskProgressMap[taskId] = progress;
        notifyListeners();
      }
      return progress;
    } catch (e) {
      return _taskProgressMap[taskId];
    }
  }

  /// Get Project Task Types/Stages (`project.task.type/web_search_read`)
  Future<List<ProjectTaskTypeModel>> loadTaskTypesForProject(
      int projectId) async {
    if (_projectTaskTypes.containsKey(projectId)) {
      return _projectTaskTypes[projectId]!;
    }

    try {
      final types = await _odooService.getProjectTaskTypes(projectId);
      _projectTaskTypes[projectId] = types;
      notifyListeners();
      return types;
    } catch (e) {
      return [];
    }
  }
}
