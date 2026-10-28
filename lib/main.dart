import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_constants.dart';
import 'package:todolist_app/core/theme/app_theme.dart';
import 'package:todolist_app/presentation/providers/filter_provider.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
      ],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
