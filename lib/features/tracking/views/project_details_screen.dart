import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/projects_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final ProjectModel project;
  final int? initialTaskId;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
    this.initialTaskId,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _isLoading = true;
  List<ProjectTaskModel> _tasks = [];
  final Map<int, CustomerTaskStageProgressModel> _taskProgressMap = {};

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  Future<void> _fetchProjectData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final controller = Provider.of<ProjectsController>(context, listen: false);

    // Refresh project data to ensure latest stage
    await controller.loadProjects(projectId: widget.project.id);

    // Load tasks for project
    final tasks = await controller.loadTasksForProject(widget.project.id);

    // Fetch customer stage progress for each task using get_customer_stage_progress([task.id])
    final Map<int, CustomerTaskStageProgressModel> progressMap = {};
    for (final task in tasks) {
      final progress = await controller.loadTaskProgress(task.id, forceRefresh: true);
      if (progress != null) {
        progressMap[task.id] = progress;
      }
    }

    if (mounted) {
      setState(() {
        _tasks = tasks;
        _taskProgressMap.clear();
        _taskProgressMap.addAll(progressMap);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtain updated project model from controller if available
    final controller = Provider.of<ProjectsController>(context);
    final currentProject = controller.projects.firstWhere(
          (p) => p.id == widget.project.id,
      orElse: () => widget.project,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Column(
        children: [
          CustomAppBar(
            title: currentProject.name.isNotEmpty
                ? currentProject.name
                : 'Project #${currentProject.id}',
            subtitle: 'Live Tracking & Task Stage Progress',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: FourRotatingDotsLoader())
                : RefreshIndicator(
              color: const Color(0xFFC4913F),
              onRefresh: _fetchProjectData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Overview Header Card
                    _buildProjectOverviewCard(currentProject),

                    const SizedBox(height: 24),

                    // Section Header: Project Tasks & Stage Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROJECT TASKS & PROGRESS',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC4913F),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4913F).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_tasks.length} ${_tasks.length == 1 ? "Task" : "Tasks"}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC4913F),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_tasks.isEmpty)
                      _buildEmptyTasksView()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          final progress = _taskProgressMap[task.id];
                          final isHighlighted = widget.initialTaskId != null && widget.initialTaskId == task.id;
                          return _buildTaskProgressCard(task, progress, isHighlighted);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectOverviewCard(ProjectModel project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1813),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A231C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: Color(0xFFC4913F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name.isNotEmpty
                          ? project.name
                          : 'Project #${project.id}',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project ID: ${project.id}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFFB5A995),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF332B22), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECT STATUS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC4913F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC4913F).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      project.stageName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC4913F),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL TASKS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.taskCount}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasksView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE7DF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_outlined,
            size: 40,
            color: Color(0xFFD6C8B4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Tasks Registered',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A2F1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tasks for this project will appear here as work progresses.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: const Color(0xFF7A7A7E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressCard(
      ProjectTaskModel task,
      CustomerTaskStageProgressModel? progress,
      bool isHighlighted,
      ) {
    final taskName = progress?.taskName.isNotEmpty == true ? progress!.taskName : task.name;
    final stages = progress?.stages ?? [];
    final currentStageName = progress?.currentStageName ?? task.stageName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFC4913F) : const Color(0xFFEBE7DF),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFC4913F).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title & State Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC4913F).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: Color(0xFFC4913F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1813),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Task ID: ${task.id}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            color: const Color(0xFF8C8273),
                          ),
                        ),
                        if (currentStageName.isNotEmpty) ...[
                          Text('•', style: TextStyle(color: Colors.grey.shade400)),
                          Text(
                            'Current Stage: $currentStageName',
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC4913F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0ECE1), height: 1),
          const SizedBox(height: 20),

          // Render Dynamic Task Customer Stage Progress Stepper
          if (stages.isEmpty)
            _buildFallbackTaskStage(task)
          else
            _buildCustomerStageStepper(stages),
        ],
      ),
    );
  }

  Widget _buildCustomerStageStepper(List<TaskStageItemModel> stages) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        final isLast = index == stages.length - 1;
        final isDone = stage.status == 'done';
        final isCurrent = stage.status == 'current';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper Line & Indicator Node
              Column(
                children: [
                  // Step Indicator Symbol (✓ done, ● current, ○ pending)
                  if (isDone)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC4913F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else if (isCurrent)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC4913F),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC4913F).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC4913F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD6C8B4),
                          width: 2,
                        ),
                      ),
                    ),

                  // Vertical Line Connector
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isDone
                            ? const Color(0xFFC4913F)
                            : const Color(0xFFE5DFC9),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Stage Details Text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            stage.name,
                            style: GoogleFonts.outfit(
                              fontSize: isCurrent ? 15.5 : 14,
                              fontWeight: isCurrent || isDone
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCurrent
                                  ? const Color(0xFF1D1813)
                                  : isDone
                                      ? const Color(0xFF3A2F1E)
                                      : const Color(0xFF9E9384),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC4913F).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'IN PROGRESS',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC4913F),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDone
                            ? 'Completed'
                            : isCurrent
                            ? 'Currently in stage'
                            : 'Pending',
                        style: GoogleFonts.montserrat(
                          fontSize: 11.5,
                          color: isCurrent
                              ? const Color(0xFFC4913F)
                              : const Color(0xFF9E9384),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackTaskStage(ProjectTaskModel task) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 18, color: Color(0xFFC4913F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Current Stage: ${task.stageName}',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A2F1E),
            ),
          ),
        ),
      ],
    );
  }
}
