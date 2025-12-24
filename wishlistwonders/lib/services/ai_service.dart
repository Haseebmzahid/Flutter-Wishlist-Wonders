import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/action_item.dart';

class AIService {
  // OpenRouter API Key - Configured and ready to use
  // For production, consider using environment variables or secure storage
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  AIService();

  /// Generates an action plan using Gemini AI based on the user's goal
  Future<ActionPlan> generateActionPlan(String goal) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🎯 AI SERVICE: generateActionPlan called');
    debugPrint('📝 Goal received: "$goal"');
    debugPrint('═══════════════════════════════════════════════════');

    if (goal.trim().isEmpty) {
      debugPrint('❌ Error: Goal is empty');
      throw Exception('Goal cannot be empty');
    }

    // Create the system prompt
    final prompt =
        '''
You are a career coach. The user wants to achieve: "$goal"

Return ONLY a valid JSON response (no markdown, no code blocks, no extra text) with the following structure:
{
  "skills": ["skill1", "skill2", "skill3", "skill4", "skill5"],
  "education": ["path1", "path2", "path3", "path4", "path5"],
  "networking": ["goal1", "goal2", "goal3", "goal4", "goal5"],
  "milestones": ["milestone1", "milestone2", "milestone3", "milestone4", "milestone5"]
}

Requirements:
- Provide exactly 5 items for each category
- Skills should be specific technical or soft skills needed
- Education should include courses, certifications, or learning paths
- Networking should include actionable networking goals
- Milestones should be short-term (1-6 months) achievable goals
- Make recommendations specific to the goal
- Return ONLY the JSON, nothing else
''';

    try {
      // Generate content using DeepSeek
      debugPrint('📡 Sending request to OpenRouter API...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat',
          'provider': {
            'order': ['DeepSeek'],
          },
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful career coach assistant.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        }),
      );

      debugPrint(
        '📥 Received response from DeepSeek (Status: ${response.statusCode})',
      );

      if (response.statusCode != 200) {
        debugPrint('❌ API Error: ${response.body}');
        throw Exception('DeepSeek API error: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          responseData['choices'][0]['message']['content'] as String;

      if (content.isEmpty) {
        debugPrint('❌ Empty response from AI');
        throw Exception('Empty response from AI');
      }

      debugPrint('✅ Response text length: ${content.length}');
      debugPrint(
        '📝 Raw response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...',
      );

      // Parse the JSON response
      final jsonResponse = _parseJsonFromResponse(content);
      debugPrint('✅ JSON parsed successfully');

      // Convert to ActionPlan
      final actionPlan = _parseActionPlan(goal, jsonResponse);
      debugPrint('✅ ActionPlan created successfully');

      return actionPlan;
    } catch (e) {
      // If AI fails, provide a fallback plan
      debugPrint('❌ AI generation error: $e');
      throw Exception('Failed to generate action plan: $e');
    }
  }

  /// Parses JSON from the AI response, handling potential formatting issues
  Map<String, dynamic> _parseJsonFromResponse(String responseText) {
    try {
      // Remove potential markdown code blocks
      String cleanedText = responseText.trim();

      // Remove markdown code block markers if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      // Parse JSON
      return jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse JSON response: $e');
    }
  }

  /// Converts the parsed JSON into an ActionPlan object
  ActionPlan _parseActionPlan(String goal, Map<String, dynamic> json) {
    try {
      // Extract lists from JSON
      final skills =
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final education =
          (json['education'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final networking =
          (json['networking'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final milestones =
          (json['milestones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Validate we have data
      if (skills.isEmpty ||
          education.isEmpty ||
          networking.isEmpty ||
          milestones.isEmpty) {
        throw Exception('Incomplete data from AI response');
      }

      // Create ActionPlan
      return ActionPlan(
        userGoal: goal,
        skillsToDevelop: skills.map((s) => ActionItem(title: s)).toList(),
        educationalPaths: education.map((e) => ActionItem(title: e)).toList(),
        networkingGoals: networking.map((n) => ActionItem(title: n)).toList(),
        shortTermMilestones: milestones
            .map((m) => ActionItem(title: m))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to create action plan from JSON: $e');
    }
  }

  /// Generates a motivational quote using OpenRouter AI
  Future<String> generateMotivationalQuote() async {
    final prompt = '''
Generate a single inspirational quote about achieving goals and personal growth.
Return ONLY the quote text, nothing else. Keep it under 100 characters.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.8,
          'max_tokens': 100,
          'provider': {
            'order': ['DeepSeek'],
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            responseData['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        return _getFallbackQuote();
      }
    } catch (e) {
      return _getFallbackQuote();
    }
  }

  /// Provides fallback quotes if AI generation fails
  String _getFallbackQuote() {
    final quotes = [
      "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      "The only way to do great work is to love what you do.",
      "Don't watch the clock; do what it does. Keep going.",
      "The future depends on what you do today.",
      "Believe you can and you're halfway there.",
    ];
    quotes.shuffle();
    return quotes.first;
  }
}
