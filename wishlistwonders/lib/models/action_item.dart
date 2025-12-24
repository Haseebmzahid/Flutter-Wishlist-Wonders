class ActionItem {
  final String title;
  bool isCompleted;

  ActionItem({required this.title, this.isCompleted = false});

  // Serialization for Firebase Realtime Database
  Map<String, dynamic> toJson() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class ActionPlan {
  final String userGoal;
  final List<ActionItem> skillsToDevelop;
  final List<ActionItem> educationalPaths;
  final List<ActionItem> networkingGoals;
  final List<ActionItem> shortTermMilestones;

  ActionPlan({
    required this.userGoal,
    required this.skillsToDevelop,
    required this.educationalPaths,
    required this.networkingGoals,
    required this.shortTermMilestones,
  });

  // Calculate overall progress
  double get progressPercentage {
    int total =
        skillsToDevelop.length +
        educationalPaths.length +
        networkingGoals.length +
        shortTermMilestones.length;

    if (total == 0) return 0;

    int completed =
        skillsToDevelop.where((item) => item.isCompleted).length +
        educationalPaths.where((item) => item.isCompleted).length +
        networkingGoals.where((item) => item.isCompleted).length +
        shortTermMilestones.where((item) => item.isCompleted).length;

    return completed / total;
  }

  // Serialization for Firebase Realtime Database
  Map<String, dynamic> toJson() {
    return {
      'userGoal': userGoal,
      'skillsToDevelop': skillsToDevelop.map((item) => item.toJson()).toList(),
      'educationalPaths': educationalPaths
          .map((item) => item.toJson())
          .toList(),
      'networkingGoals': networkingGoals.map((item) => item.toJson()).toList(),
      'shortTermMilestones': shortTermMilestones
          .map((item) => item.toJson())
          .toList(),
    };
  }

  factory ActionPlan.fromJson(Map<String, dynamic> json) {
    return ActionPlan(
      userGoal: json['userGoal'] as String,
      skillsToDevelop:
          (json['skillsToDevelop'] as List<dynamic>?)
              ?.map((item) => ActionItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      educationalPaths:
          (json['educationalPaths'] as List<dynamic>?)
              ?.map((item) => ActionItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      networkingGoals:
          (json['networkingGoals'] as List<dynamic>?)
              ?.map((item) => ActionItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      shortTermMilestones:
          (json['shortTermMilestones'] as List<dynamic>?)
              ?.map((item) => ActionItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
