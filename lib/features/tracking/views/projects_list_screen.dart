import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_app_bar.dart';
import 'package:timeless_detailing_customer_app/core/widgets/custom_loader.dart';
import 'package:timeless_detailing_customer_app/features/tracking/controllers/projects_controller.dart';
import 'package:timeless_detailing_customer_app/features/tracking/models/project_model.dart';
import 'package:timeless_detailing_customer_app/features/tracking/views/project_details_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const ProjectsListScreen({super.key, this.onMenuTap});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsController>(context, listen: false).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProjectsController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Live Track - Projects',
            showBackButton: true,
            onBackPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else if (widget.onMenuTap != null) {
                widget.onMenuTap!();
              }
            },
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: FourRotatingDotsLoader())
                : RefreshIndicator(
                    color: const Color(0xFFC4913F),
                    onRefresh: () => controller.loadProjects(),
                    child: controller.projects.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFC4913F,
                                          ).withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.track_changes_outlined,
                                          size: 48,
                                          color: Color(0xFFC4913F),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Active Projects Found',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF3A2F1E),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Live project tracking updates and service events will appear here.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          color: const Color(0xFF7A7A7E),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.projects.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final project = controller.projects[index];
                              return _buildProjectCard(context, project);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsScreen(project: project),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBE7DF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gold project badge icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC4913F).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC4913F).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                color: Color(0xFFC4913F),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Project title & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name.isNotEmpty
                        ? project.name
                        : 'Project #${project.id}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D1813),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Dynamic Project Status Badge from API
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC4913F).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFC4913F).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Status: ${project.stageName}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC4913F),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4ECE0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${project.taskCount} ${project.labelTasks.isNotEmpty ? project.labelTasks : "Tasks"}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8C6D37),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron action
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFFC4913F),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
