import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rtdb_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final _rtdbService = RTDBService();

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🏆 Loading leaderboard...');
      final users = await _rtdbService.getAllUsersForLeaderboard();
      debugPrint('🏆 Found ${users.length} users');

      for (var user in users) {
        debugPrint('   - ${user['email']}: ${user['totalXP']} XP');
      }

      // Sort by totalXP in descending order
      users.sort(
        (a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int),
      );

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 3)}***@$domain';
  }

  Widget _getMedalIcon(int rank) {
    switch (rank) {
      case 0:
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.grey, size: 28);
      case 2:
        return const Icon(
          Icons.emoji_events,
          color: Color(0xFFCD7F32),
          size: 24,
        );
      default:
        return const SizedBox(width: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade400, Colors.blue.shade200],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _users.isEmpty
            ? const Center(
                child: Text(
                  'No users yet!\nBe the first to complete tasks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final userId = user['userId'] as String;
                    final email = user['email'] as String;
                    final xp = user['totalXP'] as int;
                    final isCurrentUser = userId == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? Colors.deepPurple.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Rank number
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Medal for top 3
                            _getMedalIcon(index),
                          ],
                        ),
                        title: Text(
                          _maskEmail(email),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCurrentUser
                                ? Colors.deepPurple
                                : Colors.black87,
                          ),
                        ),
                        subtitle: isCurrentUser
                            ? const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade400,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$xp XP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
