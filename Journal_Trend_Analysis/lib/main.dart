import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/recent_provider.dart';
import 'providers/report_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/topics_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/database_papers_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/researcher_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  runApp(const JournalTrendApp());
}

class JournalTrendApp extends StatelessWidget {
  const JournalTrendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..load()),
        ChangeNotifierProvider(create: (_) => TopicsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => RecentProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..loadBookmarks()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return Consumer2<SearchProvider, DashboardProvider>(
            builder: (context, search, dashboard, _) {
              search.attachDashboardHook(
                (pubs, query, total) =>
                    dashboard.recompute(pubs, query: query, apiTotalCount: total),
              );
              search.attachProfileHook((_) {
                context.read<ProfileProvider>().recordSearch();
              });
              return MaterialApp(
                title: 'ResearchHub',
                debugShowCheckedModeBanner: false,
                themeMode: theme.themeMode,
                theme: _buildLightTheme(),
                darkTheme: _buildDarkTheme(),
                home: const _RootScreen(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/register': (context) => const RegisterScreen(),
                  '/forgot-password': (context) => const ForgotPasswordScreen(),
                  '/bookmarks': (context) => const BookmarksScreen(),
                  '/profile': (context) => const ProfileScreen(),
                  '/notifications': (context) => const NotificationsScreen(),
                  '/reports': (context) => const ReportsScreen(),
                  '/database-papers': (context) => const DatabasePapersScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const seed = Color(0xFF6366F1);

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: const Color(0xFFF0F2F8),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F2F8),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: seed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBarrierColor: Colors.black26,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const seed = Color(0xFF818CF8);

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F0F1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1A1A2E),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: seed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF6E6E8A)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBarrierColor: Colors.black38,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      switch (auth.user!.roleId) {
        case '1':
          return const AdminHomeScreen();
        case '2':
          return const ResearcherHomeScreen();
        default:
          return const HomeShell();
      }
    }

    return const LoginScreen();
  }
}
