import '../models/action_item.dart';

class ActionPlanData {
  static List<String> motivationalQuotes = [
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "The only way to do great work is to love what you do.",
    "Don't watch the clock; do what it does. Keep going.",
    "The future depends on what you do today.",
    "Believe you can and you're halfway there.",
    "Success is the sum of small efforts repeated day in and day out.",
  ];

  static ActionPlan generateActionPlan(String userGoal) {
    return ActionPlan(
      userGoal: userGoal,
      skillsToDevelop: [
        ActionItem(title: 'Master Strategic Thinking'),
        ActionItem(title: 'Develop Leadership Skills'),
        ActionItem(title: 'Learn Digital Marketing'),
        ActionItem(title: 'Improve Communication'),
        ActionItem(title: 'Build Financial Literacy'),
      ],
      educationalPaths: [
        ActionItem(title: 'MBA or Business Management Course'),
        ActionItem(title: 'Marketing Certification (Google/HubSpot)'),
        ActionItem(title: 'Leadership Training Program'),
        ActionItem(title: 'Industry-specific Workshops'),
      ],
      networkingGoals: [
        ActionItem(title: 'Connect with 5 industry leaders on LinkedIn'),
        ActionItem(title: 'Attend 2 industry conferences this year'),
        ActionItem(title: 'Join professional associations'),
        ActionItem(title: 'Find a mentor in your field'),
      ],
      shortTermMilestones: [
        ActionItem(title: 'Update resume and LinkedIn profile'),
        ActionItem(title: 'Complete one online course this month'),
        ActionItem(title: 'Read 2 books on leadership'),
        ActionItem(title: 'Schedule informational interviews'),
        ActionItem(title: 'Start a portfolio or personal project'),
      ],
    );
  }

  static String getRandomQuote() {
    motivationalQuotes.shuffle();
    return motivationalQuotes.first;
  }
}
