import 'package:flutter_test/flutter_test.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

void main() {
  group('Endpoint 8 ProjectModel Tests', () {
    test('ProjectModel parses Endpoint 8 JSON correctly', () {
      final json = {
        'id': 14,
        'name': 'Detailing Bay Alpha',
        'task_count': 5,
        'label_tasks': 'In Progress, To Do',
      };

      final project = ProjectModel.fromJson(json);

      expect(project.id, equals(14));
      expect(project.name, equals('Detailing Bay Alpha'));
      expect(project.taskCount, equals(5));
      expect(project.labelTasks, equals('In Progress, To Do'));
    });

    test('ProjectModel handles string IDs and task_count fallback', () {
      final json = {
        'id': '15',
        'name': 'Ceramic Shield Workshop',
        'task_count': 3.0,
        'label_tasks': 'Done',
      };

      final project = ProjectModel.fromJson(json);

      expect(project.id, equals(15));
      expect(project.name, equals('Ceramic Shield Workshop'));
      expect(project.taskCount, equals(3));
      expect(project.labelTasks, equals('Done'));
    });
  });
}
