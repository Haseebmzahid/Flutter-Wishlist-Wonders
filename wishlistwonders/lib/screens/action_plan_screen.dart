import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import '../providers/goal_provider.dart';
import '../models/action_item.dart';
import '../services/rtdb_service.dart';

class ActionPlanScreen extends StatefulWidget {
  const ActionPlanScreen({super.key});

  @override
  State<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends State<ActionPlanScreen> {
  late ConfettiController _confettiController;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkForCompletion(double currentProgress) {
    if (currentProgress == 1.0 && _lastProgress < 1.0) {
      _confettiController.play();
    }
    _lastProgress = currentProgress;
  }

  Future<void> _toggleItem(BuildContext context, ActionItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final wasCompleted = item.isCompleted;

    // Toggle the item
    goalProvider.toggleActionItem(item);

    // Update XP based on completion status
    final rtdbService = RTDBService();
    try {
      if (!wasCompleted) {
        // Item was just completed - add 10 XP
        await rtdbService.updateUserXP(user.uid, 10);
      } else {
        // Item was unchecked - remove 10 XP
        await rtdbService.updateUserXP(user.uid, -10);
      }
    } catch (e) {
      debugPrint('Failed to update XP: $e');
    }
  }

  Future<void> _saveProgress(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please sign in to save progress'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final actionPlan = goalProvider.actionPlan;

    if (actionPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No action plan to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final rtdbService = RTDBService();
      await rtdbService.saveUserPlan(user.uid, actionPlan);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Progress saved to cloud successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, child) {
        final actionPlan = goalProvider.actionPlan;
        final userGoal = goalProvider.userGoal;
        final motivationalQuote = goalProvider.motivationalQuote;
        final progress = goalProvider.progressPercentage;
        final isLoading = goalProvider.isLoading;
        final errorMessage = goalProvider.errorMessage;

        // Check for completion and trigger confetti
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForCompletion(progress);
        });

        // Show loading state while AI is generating
        if (isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Action Plan'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple.shade400, Colors.blue.shade300],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🤖 AI is crafting your\npersonalized action plan...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This may take a few moments',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // If no action plan exists, show error state
        if (actionPlan == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Action Plan'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No action plan available. Please set a goal first.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Action Plan'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard),
                onPressed: () {
                  Navigator.pushNamed(context, '/leaderboard');
                },
                tooltip: 'Leaderboard',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveProgress(context),
                tooltip: 'Save Progress',
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show warning if using fallback data
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.orange.shade100,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Goal Header with Progress
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.blue.shade300,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🎯 Your Goal',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userGoal,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Pie Chart Progress Indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 45,
                                    sections: [
                                      PieChartSectionData(
                                        value: progress * 100,
                                        color: Colors.white,
                                        title: '',
                                        radius: 25,
                                      ),
                                      PieChartSectionData(
                                        value: (1 - progress) * 100,
                                        color: Colors.white.withOpacity(0.3),
                                        title: '',
                                        radius: 25,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Motivational Quote Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Colors.amber.shade50,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.format_quote,
                                color: Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  motivationalQuote,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Action Items Sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildActionSection(
                            context: context,
                            title: '💪 Skills to Develop',
                            items: actionPlan.skillsToDevelop,
                            icon: Icons.psychology,
                            color: Colors.deepPurple,
                            goalProvider: goalProvider,
                          ),
                          const SizedBox(height: 16),
                          _buildActionSection(
                            context: context,
                            title: '📚 Educational Paths',
                            items: actionPlan.educationalPaths,
                            icon: Icons.school,
                            color: Colors.blue,
                            goalProvider: goalProvider,
                          ),
                          const SizedBox(height: 16),
                          _buildActionSection(
                            context: context,
                            title: '🤝 Networking Goals',
                            items: actionPlan.networkingGoals,
                            icon: Icons.people,
                            color: Colors.green,
                            goalProvider: goalProvider,
                          ),
                          const SizedBox(height: 16),
                          _buildActionSection(
                            context: context,
                            title: '🎯 Short-term Milestones',
                            items: actionPlan.shortTermMilestones,
                            icon: Icons.flag,
                            color: Colors.orange,
                            goalProvider: goalProvider,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Confetti Widget
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 1.57, // downward (π/2)
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.3,
                  colors: const [
                    Colors.deepPurple,
                    Colors.amber,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _saveProgress(context),
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.save),
            label: const Text('Save Progress'),
          ),
        );
      },
    );
  }

  Widget _buildActionSection({
    required BuildContext context,
    required String title,
    required List<ActionItem> items,
    required IconData icon,
    required Color color,
    required GoalProvider goalProvider,
  }) {
    final completedCount = goalProvider.getCompletedCount(items);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount/${items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items List
          ...items.map((item) {
            return CheckboxListTile(
              title: Text(
                item.title,
                style: TextStyle(
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
              value: item.isCompleted,
              onChanged: (value) => _toggleItem(context, item),
              activeColor: color,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }
}
