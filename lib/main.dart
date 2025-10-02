import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/screens/main_screen.dart';
import 'database/database_helper.dart';
import 'package:payments_tracker_flutter/screens/choose_account_screen.dart';
import 'package:payments_tracker_flutter/global_variables/app_colors.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: false);

    return MaterialApp(
      title: 'Payments Tracker',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: AppColors.deepPurple,
          onPrimary: Colors.white,
          secondary: AppColors.subtlePurple,
          onSecondary: Colors.white,
          surface: AppColors.offWhite,
          onSurface: AppColors.deepPurple,
          background: Colors.white,
          onBackground: AppColors.deepPurple,
          error: AppColors.expenseRed,
          onError: Colors.white,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: AppColors.deepPurple,
          displayColor: AppColors.deepPurple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.deepPurple,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: const StadiumBorder(),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.deepPurple,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.deepPurple,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        cardTheme: baseTheme.cardTheme.copyWith(
          color: AppColors.offWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: const ChooseAccountScreen(),
    );
  }
}
