import 'package:flutter/material.dart';
import '../services/rtdb_service.dart';

/// One-time migration screen to copy user data to public_leaderboard
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isRunning = false;
  String _status = 'Ready to migrate existing users to public leaderboard';

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Migration in progress...';
    });

    try {
      await RTDBService().migrateToPublicLeaderboard();
      setState(() {
        _status = '✅ Migration completed successfully!';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Migration failed: $e';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_sync, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                'One-Time Migration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isRunning)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _runMigration,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'This will copy existing user XP and emails\nto the public_leaderboard node.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
