class ProjectModel {
  final int id;
  final String name;
  final int taskCount;
  final String labelTasks;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.taskCount,
    required this.labelTasks,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      taskCount: json['task_count'] is int
          ? json['task_count'] as int
          : (json['task_count'] as num?)?.toInt() ?? 0,
      labelTasks: json['label_tasks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'task_count': taskCount,
    'label_tasks': labelTasks,
  };
}

class ProjectTaskModel {
  final int id;
  final String name;
  final String priority;
  final List<String> portalUserNames;
  final String state;
  final int stageId;
  final String stageName;
  final int projectId;
  final String projectName;

  const ProjectTaskModel({
    required this.id,
    required this.name,
    required this.priority,
    required this.portalUserNames,
    required this.state,
    required this.stageId,
    required this.stageName,
    required this.projectId,
    required this.projectName,
  });

  factory ProjectTaskModel.fromJson(Map<String, dynamic> json) {
    List<String> users = [];
    if (json['portal_user_names'] is List) {
      users = (json['portal_user_names'] as List).map((u) => u.toString()).toList();
    }

    int parsedStageId = 0;
    String parsedStageName = '';
    if (json['stage_id'] is List && (json['stage_id'] as List).isNotEmpty) {
      final list = json['stage_id'] as List;
      parsedStageId = list[0] is int ? list[0] as int : 0;
      if (list.length > 1) parsedStageName = list[1].toString();
    } else if (json['stage_id'] is Map) {
      parsedStageId = json['stage_id']['id'] is int ? json['stage_id']['id'] as int : 0;
      parsedStageName = json['stage_id']['name']?.toString() ?? '';
    }

    int parsedProjectId = 0;
    String parsedProjectName = '';
    if (json['project_id'] is List && (json['project_id'] as List).isNotEmpty) {
      final list = json['project_id'] as List;
      parsedProjectId = list[0] is int ? list[0] as int : 0;
      if (list.length > 1) parsedProjectName = list[1].toString();
    } else if (json['project_id'] is Map) {
      parsedProjectId = json['project_id']['id'] is int ? json['project_id']['id'] as int : 0;
      parsedProjectName = json['project_id']['name']?.toString() ?? '';
    }

    return ProjectTaskModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '0',
      portalUserNames: users,
      state: json['state']?.toString() ?? '',
      stageId: parsedStageId,
      stageName: parsedStageName,
      projectId: parsedProjectId,
      projectName: parsedProjectName,
    );
  }
}
