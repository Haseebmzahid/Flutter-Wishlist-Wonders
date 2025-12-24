import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/goal_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/migration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoalProvider(),
      child: MaterialApp(
        title: 'WishlistWonders',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        routes: {
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/migration': (context) => const MigrationScreen(),
        },
      ),
    );
  }
}
