import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/projects_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _isLoading = true;
  List<ProjectTaskTypeModel> _stages = [];
  List<ProjectTaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  Future<void> _fetchProjectData() async {
    setState(() => _isLoading = true);
    final controller = Provider.of<ProjectsController>(context, listen: false);
    final stages = await controller.loadTaskTypesForProject(widget.project.id);
    final tasks = await controller.loadTasksForProject(widget.project.id);

    if (mounted) {
      setState(() {
        _stages = stages;
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Column(
        children: [
          CustomAppBar(
            title: widget.project.name.isNotEmpty
                ? widget.project.name
                : 'Project #${widget.project.id}',
            subtitle: 'Live Tracking Events & Stages',
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
                          _buildProjectOverviewCard(),

                          const SizedBox(height: 24),

                          // Section Title: Live Project Events & Stages
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SERVICE EVENTS & STAGES',
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
                                  '${_stages.length} Stages',
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

                          if (_stages.isEmpty)
                            _buildEmptyStagesView()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _stages.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final stage = _stages[index];
                                final stageTasks = _tasks
                                    .where((t) => t.stageId == stage.id || t.stageName == stage.name)
                                    .toList();
                                return _buildStageEventCard(stage, index, stageTasks);
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

  Widget _buildProjectOverviewCard() {
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
                      widget.project.name.isNotEmpty
                          ? widget.project.name
                          : 'Project Details',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Project ID: ${widget.project.id}',
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
                    'TOTAL TASKS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.project.taskCount}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC4913F),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EVENT STAGES',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8C8273),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_stages.length}',
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

  Widget _buildEmptyStagesView() {
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
            Icons.format_list_bulleted_outlined,
            size: 40,
            color: Color(0xFFD6C8B4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Events Configured',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A2F1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No project stages or task types are currently registered for this project.',
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

  Widget _buildStageEventCard(
    ProjectTaskTypeModel stage,
    int index,
    List<ProjectTaskModel> stageTasks,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Sequence badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFC4913F).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC4913F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D1813),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sequence #${stage.sequence}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: const Color(0xFF8C8273),
                      ),
                    ),
                  ],
                ),
              ),
              if (stageTasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stageTasks.length} ${stageTasks.length == 1 ? "Task" : "Tasks"}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),

          // Render tasks inside this stage event if present
          if (stageTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0ECE1), height: 1),
            const SizedBox(height: 12),
            ...stageTasks.map((t) => _buildTaskItem(t)),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(ProjectTaskModel task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFFC4913F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.name,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3A2F1E),
              ),
            ),
          ),
          if (task.state.isNotEmpty)
            Text(
              task.state,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF7A7A7E),
              ),
            ),
        ],
      ),
    );
  }
}
