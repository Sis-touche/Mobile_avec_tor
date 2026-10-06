import 'package:go_router/go_router.dart';

import '../domain/entities/epub_file.dart';
import '../presentation/screens/browser/browser_screen.dart';
import '../presentation/screens/browser/browser_tabs_screen.dart';
import '../presentation/screens/browser/tor_mode_info_screen.dart';
import '../presentation/screens/epub_reader/epub_library_screen.dart';
import '../presentation/screens/epub_reader/epub_reader_screen.dart';
import '../presentation/screens/home/home_menu_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/reading_dashboard/reading_dashboard_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/home-menu', builder: (context, state) => const HomeMenuScreen()),
    GoRoute(path: '/browser', builder: (context, state) => const BrowserScreen()),
    GoRoute(path: '/browser-tabs', builder: (context, state) => const BrowserTabsScreen()),
    GoRoute(path: '/tor-info', builder: (context, state) => const TorModeInfoScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(
      path: '/reading-dashboard',
      builder: (context, state) => const ReadingDashboardScreen(),
    ),
    GoRoute(path: '/epub-library', builder: (context, state) => const EpubLibraryScreen()),
    GoRoute(
      path: '/epub-reader',
      builder: (context, state) => EpubReaderScreen(epubFile: state.extra as EpubFile),
    ),
  ],
);
