import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/action_item.dart';

/// Service for managing user data in Firebase Realtime Database
class RTDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Saves the user's action plan to the database
  /// Path: users/{userId}/currentPlan
  Future<void> saveUserPlan(String userId, ActionPlan plan) async {
    try {
      final DatabaseReference ref = _database.ref('users/$userId/currentPlan');
      await ref.set(plan.toJson());
    } catch (e) {
      throw Exception('Failed to save action plan: $e');
    }
  }

  /// Gets a stream of the user's action plan for real-time updates
  /// Path: users/{userId}/currentPlan
  Stream<ActionPlan?> getUserPlanStream(String userId) {
    final DatabaseReference ref = _database.ref('users/$userId/currentPlan');

    return ref.onValue.map((event) {
      if (event.snapshot.value == null) {
        return null;
      }

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final jsonData = Map<String, dynamic>.from(data);
        return ActionPlan.fromJson(jsonData);
      } catch (e) {
        print('Error parsing action plan: $e');
        return null;
      }
    });
  }

  /// Gets the user's action plan once (not a stream)
  Future<ActionPlan?> getUserPlan(String userId) async {
    try {
      final DatabaseReference ref = _database.ref('users/$userId/currentPlan');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final jsonData = Map<String, dynamic>.from(data);
      return ActionPlan.fromJson(jsonData);
    } catch (e) {
      print('Error fetching action plan: $e');
      return null;
    }
  }

  /// Deletes the user's action plan
  Future<void> deleteUserPlan(String userId) async {
    try {
      final DatabaseReference ref = _database.ref('users/$userId/currentPlan');
      await ref.remove();
    } catch (e) {
      throw Exception('Failed to delete action plan: $e');
    }
  }

  /// Updates user's XP (Experience Points)
  /// Path: users/{userId}/profile/totalXP and public_leaderboard/{userId}
  Future<void> updateUserXP(String userId, int points) async {
    try {
      final DatabaseReference profileRef = _database.ref(
        'users/$userId/profile/totalXP',
      );
      final snapshot = await profileRef.get();

      int currentXP = 0;
      if (snapshot.exists) {
        currentXP = snapshot.value as int;
      }

      final newXP = currentXP + points;
      final finalXP = newXP >= 0 ? newXP : 0; // Prevent negative XP

      // Update private profile XP
      await profileRef.set(finalXP);

      // Also update public leaderboard
      final DatabaseReference emailRef = _database.ref(
        'users/$userId/profile/email',
      );
      final emailSnapshot = await emailRef.get();
      final email = emailSnapshot.exists
          ? emailSnapshot.value.toString()
          : 'Unknown';

      final DatabaseReference leaderboardRef = _database.ref(
        'public_leaderboard/$userId',
      );
      await leaderboardRef.set({'email': email, 'totalXP': finalXP});

      debugPrint('✅ Updated XP: $finalXP for user $email');
    } catch (e) {
      debugPrint('❌ Failed to update XP: $e');
      throw Exception('Failed to update XP: $e');
    }
  }

  /// Gets all users with their profiles for leaderboard
  /// Returns a list of maps with userId, email, and totalXP
  Future<List<Map<String, dynamic>>> getAllUsersForLeaderboard() async {
    try {
      debugPrint('📊 Fetching leaderboard from public_leaderboard node...');
      final DatabaseReference leaderboardRef = _database.ref(
        'public_leaderboard',
      );

      debugPrint('📊 Using once() method for read...');
      final DatabaseEvent event = await leaderboardRef.once();
      final DataSnapshot snapshot = event.snapshot;

      debugPrint('📊 Snapshot exists: ${snapshot.exists}');

      if (!snapshot.exists) {
        debugPrint('⚠️ No leaderboard data found');
        return [];
      }

      final dynamic snapshotValue = snapshot.value;
      debugPrint('📊 Snapshot value type: ${snapshotValue.runtimeType}');

      if (snapshotValue == null) {
        debugPrint('⚠️ Snapshot value is null');
        return [];
      }

      if (snapshotValue is! Map) {
        debugPrint('❌ Unexpected data type: ${snapshotValue.runtimeType}');
        return [];
      }

      // Convert to Map<String, dynamic>
      final Map<String, dynamic> leaderboardMap = {};
      snapshotValue.forEach((key, value) {
        leaderboardMap[key.toString()] = value;
      });

      debugPrint('📊 Found ${leaderboardMap.length} user entries');
      final List<Map<String, dynamic>> users = [];

      for (var entry in leaderboardMap.entries) {
        final String userId = entry.key;
        final dynamic userData = entry.value;

        debugPrint('   Processing user: $userId');

        if (userData == null || userData is! Map) {
          debugPrint('   ⚠️ Skipping $userId - invalid data type');
          continue;
        }

        // Convert userData to Map<String, dynamic>
        final Map<String, dynamic> userDataMap = {};
        userData.forEach((key, value) {
          userDataMap[key.toString()] = value;
        });

        final String email = userDataMap['email']?.toString() ?? 'Unknown';
        final int totalXP = (userDataMap['totalXP'] is int)
            ? userDataMap['totalXP'] as int
            : ((userDataMap['totalXP'] is double)
                  ? (userDataMap['totalXP'] as double).toInt()
                  : 0);

        debugPrint('   ✅ User: $email with $totalXP XP');

        users.add({'userId': userId, 'email': email, 'totalXP': totalXP});
      }

      debugPrint(
        '✅ Successfully processed ${users.length} users for leaderboard',
      );
      return users;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching leaderboard: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Saves user profile (email) - call this on first login
  Future<void> saveUserProfile(String userId, String email) async {
    try {
      // Save private profile
      final DatabaseReference profileRef = _database.ref(
        'users/$userId/profile',
      );
      await profileRef.set({'email': email, 'totalXP': 0});

      // Also create public leaderboard entry
      final DatabaseReference leaderboardRef = _database.ref(
        'public_leaderboard/$userId',
      );
      await leaderboardRef.set({'email': email, 'totalXP': 0});

      debugPrint('✅ Created profile and leaderboard entry for $email');
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Checks if user profile exists and creates it if not
  Future<void> ensureUserProfile(String userId, String email) async {
    try {
      final DatabaseReference ref = _database.ref('users/$userId/profile');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        debugPrint('🆕 Profile doesn\'t exist, creating for $email');
        await saveUserProfile(userId, email);
        debugPrint('✅ Profile created successfully');
      } else {
        debugPrint('✅ Profile already exists for user');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring profile: $e');
      throw Exception('Failed to ensure user profile: $e');
    }
  }

  /// ONE-TIME MIGRATION: Copy existing user data to public_leaderboard
  /// Call this once to migrate existing users
  Future<void> migrateToPublicLeaderboard() async {
    try {
      debugPrint('🔄 Starting migration to public_leaderboard...');

      final DatabaseReference usersRef = _database.ref('users');
      final DatabaseEvent event = await usersRef.once();
      final DataSnapshot snapshot = event.snapshot;

      if (!snapshot.exists) {
        debugPrint('⚠️ No users to migrate');
        return;
      }

      final dynamic snapshotValue = snapshot.value;
      if (snapshotValue is! Map) {
        debugPrint('❌ Invalid users data structure');
        return;
      }

      final Map<String, dynamic> usersMap = {};
      snapshotValue.forEach((key, value) {
        usersMap[key.toString()] = value;
      });

      int migratedCount = 0;
      for (var entry in usersMap.entries) {
        final String userId = entry.key;
        final dynamic userData = entry.value;

        if (userData is! Map) continue;

        final Map<String, dynamic> userDataMap = {};
        userData.forEach((key, value) {
          userDataMap[key.toString()] = value;
        });

        final dynamic profileData = userDataMap['profile'];
        if (profileData == null || profileData is! Map) continue;

        final Map<String, dynamic> profileMap = {};
        profileData.forEach((key, value) {
          profileMap[key.toString()] = value;
        });

        final String email = profileMap['email']?.toString() ?? 'Unknown';
        final int totalXP = (profileMap['totalXP'] is int)
            ? profileMap['totalXP'] as int
            : 0;

        // Copy to public leaderboard
        final DatabaseReference leaderboardRef = _database.ref(
          'public_leaderboard/$userId',
        );
        await leaderboardRef.set({'email': email, 'totalXP': totalXP});

        migratedCount++;
        debugPrint('   ✅ Migrated $email with $totalXP XP');
      }

      debugPrint('✅ Migration complete! Migrated $migratedCount users');
    } catch (e, stackTrace) {
      debugPrint('❌ Migration failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
