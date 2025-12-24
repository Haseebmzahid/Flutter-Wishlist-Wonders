import 'package:flutter/material.dart';
import '../models/action_item.dart';
import '../data/action_plan_data.dart';
import '../services/ai_service.dart';

class GoalProvider extends ChangeNotifier {
  String _userGoal = '';
  ActionPlan? _actionPlan;
  String _motivationalQuote = '';
  bool _isLoading = false;
  String? _errorMessage;

  final AIService _aiService = AIService();

  // Getters
  String get userGoal => _userGoal;
  ActionPlan? get actionPlan => _actionPlan;
  String get motivationalQuote => _motivationalQuote;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Calculate progress percentage
  double get progressPercentage {
    if (_actionPlan == null) return 0.0;
    return _actionPlan!.progressPercentage;
  }

  // Check if action plan exists
  bool get hasActionPlan => _actionPlan != null;

  // Set the user goal without generating (for UI flow control)
  void setGoalWithoutGenerating(String goal) {
    _userGoal = goal;
    _isLoading = true;
    _errorMessage = null;
    _actionPlan = null; // Clear old plan
    notifyListeners();
    debugPrint('📝 Goal set to: $goal (waiting for generation)');
  }

  // Set the user goal and generate action plan
  Future<void> setGoal(String goal) async {
    _userGoal = goal;
    await generateActionPlan();
  }

  // Generate action plan based on user goal using AI
  Future<void> generateActionPlan() async {
    if (_userGoal.trim().isEmpty) {
      debugPrint('❌ Cannot generate plan: Goal is empty');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('\n╔════════════════════════════════════════════════════╗');
    debugPrint('║  🤖 STARTING AI GENERATION                        ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('📝 User Goal: "$_userGoal"');
    debugPrint('⏰ Time: ${DateTime.now()}');

    try {
      // Try to generate action plan using AI
      debugPrint('🤖 Calling AIService.generateActionPlan()...');
      debugPrint('🔑 API Key exists: true');

      final startTime = DateTime.now();
      _actionPlan = await _aiService.generateActionPlan(_userGoal);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      debugPrint('✅ AI generation successful!');
      debugPrint('⏱️  Generation took: ${duration.inSeconds} seconds');
      debugPrint('📊 Generated ${_actionPlan!.skillsToDevelop.length} skills');
      debugPrint(
        '📊 First skill: "${_actionPlan!.skillsToDevelop.first.title}"',
      );
      debugPrint('📊 Second skill: "${_actionPlan!.skillsToDevelop[1].title}"');

      // Try to generate motivational quote using AI
      try {
        _motivationalQuote = await _aiService.generateMotivationalQuote();
      } catch (e) {
        // If quote generation fails, use fallback
        _motivationalQuote = ActionPlanData.getRandomQuote();
      }

      _errorMessage = null;
    } catch (e, stackTrace) {
      // If AI generation fails, use fallback to hardcoded data
      debugPrint('╔════════════════════════════════════════════════════╗');
      debugPrint('║  ❌ AI GENERATION FAILED                          ║');
      debugPrint('╚════════════════════════════════════════════════════╝');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('🔄 Using fallback data instead.');

      _actionPlan = ActionPlanData.generateActionPlan(_userGoal);
      _motivationalQuote = ActionPlanData.getRandomQuote();
      _errorMessage =
          'Using sample data. AI error: ${e.toString().substring(0, 100)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Regenerate motivational quote
  void refreshQuote() {
    _motivationalQuote = ActionPlanData.getRandomQuote();
    notifyListeners();
  }

  // Toggle completion status of an action item
  void toggleActionItem(ActionItem item) {
    item.isCompleted = !item.isCompleted;
    notifyListeners();
  }

  // Clear all data (useful for resetting)
  void clearGoal() {
    _userGoal = '';
    _actionPlan = null;
    _motivationalQuote = '';
    notifyListeners();
  }

  // Get completed items count for a specific list
  int getCompletedCount(List<ActionItem> items) {
    return items.where((item) => item.isCompleted).length;
  }

  // Get total items count
  int getTotalItemsCount() {
    if (_actionPlan == null) return 0;

    return _actionPlan!.skillsToDevelop.length +
        _actionPlan!.educationalPaths.length +
        _actionPlan!.networkingGoals.length +
        _actionPlan!.shortTermMilestones.length;
  }

  // Get total completed items count
  int getTotalCompletedCount() {
    if (_actionPlan == null) return 0;

    return getCompletedCount(_actionPlan!.skillsToDevelop) +
        getCompletedCount(_actionPlan!.educationalPaths) +
        getCompletedCount(_actionPlan!.networkingGoals) +
        getCompletedCount(_actionPlan!.shortTermMilestones);
  }
}
