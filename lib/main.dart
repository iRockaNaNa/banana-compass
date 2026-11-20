import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'models/app_state.dart';
import 'models/settings.dart';
import 'screens/compass_screen.dart';
import 'screens/level_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weather_screen.dart';
import 'services/purchase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  final purchaseService = PurchaseService();
  final appState = AppState();
  // Never blocks startup: a store failure just leaves the app free tier,
  // and settings fall back to the defaults.
  unawaited(settings.load());
  unawaited(purchaseService.initialize());
  unawaited(appState.start());
  runApp(BananaCompassApp(
    settings: settings,
    purchaseService: purchaseService,
    appState: appState,
  ));
}

class BananaCompassApp extends StatelessWidget {
  const BananaCompassApp({
    super.key,
    required this.settings,
    required this.purchaseService,
    required this.appState,
  });

  final AppSettings settings;
  final PurchaseService purchaseService;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Banana Compass',
          debugShowCheckedModeBanner: false,
          theme: _themeFor(settings.theme),
          home: HomeScreen(
            settings: settings,
            purchaseService: purchaseService,
            appState: appState,
          ),
        );
      },
    );
  }
}

/// Nanatech themes. Dark is the default: charcoal #121212 with lime
/// #C8FF00. Pure AMOLED is true black. Red Light is a night-vision
/// theme — red on black, so it doesn't wreck dark-adapted eyes.
ThemeData _themeFor(AppTheme theme) {
  final (Color scaffold, Color surface, Color primary, Color onPrimary,
      Color text, Color muted) = switch (theme) {
    AppTheme.dark => (
        const Color(0xFF121212),
        const Color(0xFF1E1E1E),
        const Color(0xFFC8FF00),
        Colors.black,
        Colors.white,
        const Color(0xFF9E9E9E),
      ),
    AppTheme.light => (
        const Color(0xFFF5F5F5),
        Colors.white,
        const Color(0xFF5A8F00),
        Colors.white,
        const Color(0xFF1A1A1A),
        const Color(0xFF666666),
      ),
    AppTheme.amoled => (
        Colors.black,
        const Color(0xFF0A0A0A),
        const Color(0xFFC8FF00),
        Colors.black,
        Colors.white,
        const Color(0xFF8A8A8A),
      ),
    AppTheme.red => (
        const Color(0xFF0A0000),
        const Color(0xFF1A0505),
        const Color(0xFFFF3B30),
        Colors.black,
        const Color(0xFFFFD7D7),
        const Color(0xFFB08080),
      ),
  };
  final scheme = ColorScheme(
    brightness:
        theme == AppTheme.light ? Brightness.light : Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    surface: surface,
    onSurface: text,
    error: const Color(0xFFFF6B6B),
    onError: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffold,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: text,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: muted,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: muted.withValues(alpha: 0.25)),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: text),
      bodyLarge: TextStyle(color: text),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
    ),
  );
}

/// Bottom navigation: Compass / Level / Weather, with Settings in the
/// app bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.purchaseService,
    required this.appState,
  });

  final AppSettings settings;
  final PurchaseService purchaseService;
  final AppState appState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
    widget.purchaseService.isPremium.addListener(_onPremiumChanged);
    _applyRefreshRate();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _onPremiumChanged() => _applyRefreshRate();

  void _applyRefreshRate() {
    final fast = widget.settings.fastRefresh &&
        widget.purchaseService.isPremium.value;
    widget.appState.altitudeService.setFastRefresh(fast);
    widget.appState.startWeatherTimer(fastRefresh: fast);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    widget.purchaseService.isPremium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Banana Compass', 'Level', 'Weather'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.purchaseService.isPremium,
            builder: (context, isPremium, _) {
              if (!isPremium) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.star, color: Color(0xFFFFC107)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  settings: widget.settings,
                  purchaseService: widget.purchaseService,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          CompassScreen(
            settings: widget.settings,
            purchaseService: widget.purchaseService,
            appState: widget.appState,
          ),
          LevelScreen(
            levelService: widget.appState.levelService,
          ),
          WeatherScreen(
            settings: widget.settings,
            purchaseService: widget.purchaseService,
            appState: widget.appState,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Compass',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.balance),
            label: 'Level',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
          ),
        ],
      ),
    );
  }
}
