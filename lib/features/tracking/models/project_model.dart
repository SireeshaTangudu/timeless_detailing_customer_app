class ProjectModel {
  final int id;
  final String name;
  final int taskCount;
  final String labelTasks;
  final int? stageId;
  final String stageName;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.taskCount,
    required this.labelTasks,
    this.stageId,
    this.stageName = 'To Do',
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    int? parsedStageId;
    String parsedStageName = 'To Do';

    final stageRaw = json['stage_id'];
    if (stageRaw is Map) {
      parsedStageId = stageRaw['id'] is int
          ? stageRaw['id'] as int
          : int.tryParse(stageRaw['id']?.toString() ?? '');
      if (stageRaw['name'] != null && stageRaw['name'] != false) {
        parsedStageName = stageRaw['name'].toString();
      }
    } else if (stageRaw is List && stageRaw.isNotEmpty) {
      parsedStageId = stageRaw[0] is int
          ? stageRaw[0] as int
          : int.tryParse(stageRaw[0].toString());
      if (stageRaw.length > 1 && stageRaw[1] != false) {
        parsedStageName = stageRaw[1].toString();
      }
    }

    return ProjectModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      taskCount: json['task_count'] is int
          ? json['task_count'] as int
          : (json['task_count'] as num?)?.toInt() ?? 0,
      labelTasks: json['label_tasks']?.toString() ?? 'Tasks',
      stageId: parsedStageId,
      stageName: parsedStageName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'task_count': taskCount,
        'label_tasks': labelTasks,
        'stage_id': stageId != null ? {'id': stageId, 'name': stageName} : null,
      };
}

class ProjectStageModel {
  final int id;
  final String name;
  final int sequence;
  final bool fold;

  const ProjectStageModel({
    required this.id,
    required this.name,
    required this.sequence,
    required this.fold,
  });

  factory ProjectStageModel.fromJson(Map<String, dynamic> json) {
    return ProjectStageModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : (json['sequence'] as num?)?.toInt() ?? 0,
      fold: json['fold'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequence': sequence,
        'fold': fold,
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
      users = (json['portal_user_names'] as List)
          .map((u) => u.toString())
          .toList();
    }

    int parsedStageId = 0;
    String parsedStageName = '';
    if (json['stage_id'] is List && (json['stage_id'] as List).isNotEmpty) {
      final list = json['stage_id'] as List;
      parsedStageId = list[0] is int ? list[0] as int : 0;
      if (list.length > 1) parsedStageName = list[1].toString();
    } else if (json['stage_id'] is Map) {
      parsedStageId =
          json['stage_id']['id'] is int ? json['stage_id']['id'] as int : 0;
      parsedStageName = json['stage_id']['name']?.toString() ?? '';
    }

    int parsedProjectId = 0;
    String parsedProjectName = '';
    if (json['project_id'] is List &&
        (json['project_id'] as List).isNotEmpty) {
      final list = json['project_id'] as List;
      parsedProjectId = list[0] is int ? list[0] as int : 0;
      if (list.length > 1) parsedProjectName = list[1].toString();
    } else if (json['project_id'] is Map) {
      parsedProjectId = json['project_id']['id'] is int
          ? json['project_id']['id'] as int
          : 0;
      parsedProjectName = json['project_id']['name']?.toString() ?? '';
    }

    return ProjectTaskModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
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

class ProjectTaskTypeModel {
  final int id;
  final String name;
  final int sequence;

  const ProjectTaskTypeModel({
    required this.id,
    required this.name,
    required this.sequence,
  });

  factory ProjectTaskTypeModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : (json['sequence'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequence': sequence,
      };
}

class TaskStageItemModel {
  final int id;
  final String name;
  final int sequence;
  final bool fold;
  final String status; // 'done', 'current', 'pending'

  const TaskStageItemModel({
    required this.id,
    required this.name,
    required this.sequence,
    required this.fold,
    required this.status,
  });

  factory TaskStageItemModel.fromJson(Map<String, dynamic> json) {
    return TaskStageItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : (json['sequence'] as num?)?.toInt() ?? 0,
      fold: json['fold'] == true,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequence': sequence,
        'fold': fold,
        'status': status,
      };
}

class CustomerTaskStageProgressModel {
  final int taskId;
  final String taskName;
  final int projectId;
  final String projectName;
  final String state;
  final bool isClosed;
  final int currentStageId;
  final String currentStageName;
  final List<TaskStageItemModel> stages;

  const CustomerTaskStageProgressModel({
    required this.taskId,
    required this.taskName,
    required this.projectId,
    required this.projectName,
    required this.state,
    required this.isClosed,
    required this.currentStageId,
    required this.currentStageName,
    required this.stages,
  });

  factory CustomerTaskStageProgressModel.fromJson(Map<String, dynamic> json) {
    List<TaskStageItemModel> parsedStages = [];
    if (json['stages'] is List) {
      parsedStages = (json['stages'] as List)
          .map((s) => TaskStageItemModel.fromJson(
              Map<String, dynamic>.from(s as Map)))
          .toList();
      parsedStages.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    return CustomerTaskStageProgressModel(
      taskId: json['task_id'] is int
          ? json['task_id'] as int
          : int.tryParse(json['task_id']?.toString() ?? '0') ?? 0,
      taskName: json['task_name']?.toString() ?? '',
      projectId: json['project_id'] is int
          ? json['project_id'] as int
          : int.tryParse(json['project_id']?.toString() ?? '0') ?? 0,
      projectName: json['project_name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      isClosed: json['is_closed'] == true,
      currentStageId: json['current_stage_id'] is int
          ? json['current_stage_id'] as int
          : int.tryParse(json['current_stage_id']?.toString() ?? '0') ?? 0,
      currentStageName: json['current_stage_name']?.toString() ?? '',
      stages: parsedStages,
    );
  }

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'task_name': taskName,
        'project_id': projectId,
        'project_name': projectName,
        'state': state,
        'is_closed': isClosed,
        'current_stage_id': currentStageId,
        'current_stage_name': currentStageName,
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}
