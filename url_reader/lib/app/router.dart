import 'package:go_router/go_router.dart';

import '../domain/entities/epub_file.dart';
import '../presentation/screens/browser/browser_screen.dart';
import '../presentation/screens/epub_reader/epub_library_screen.dart';
import '../presentation/screens/epub_reader/epub_reader_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/browser',
      builder: (context, state) => BrowserScreen(initialUrl: state.extra as String),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/epub-library',
      builder: (context, state) => const EpubLibraryScreen(),
    ),
    GoRoute(
      path: '/epub-reader',
      builder: (context, state) => EpubReaderScreen(epubFile: state.extra as EpubFile),
    ),
  ],
);
