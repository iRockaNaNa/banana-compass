# Banana Compass

A compass, level, altimeter, and weather app for every Android phone —
and for the PC too, as a web app. By **Nanatech Creative Studios**,
Arizona, USA.

A fresh Nanatech implementation, modeled on the feature categories and
paywall structure of "Pixel Compass: Nav & Level" (fertwbr). Not a copy
of that app's code, assets, or UI.

**No ads, ever.**

## What it does

| Feature | Free | Premium |
| --- | --- | --- |
| Compass — live heading, True / Magnetic North toggle | ✅ | |
| Coordinates — decimal degrees / DMS / DDM, NATO mils (6400) | ✅ | |
| Level tool — bubble level, custom zero (tare), lock | ✅ | |
| Altitude — barometer + pressure, manual calibration, GPS fallback | ✅ | |
| Weather — current conditions + hourly forecast (Open-Meteo, no key) | ✅ | |
| Advanced forecast chart (24-hour line chart) | | ✅ |
| Exclusive compass shapes and themes (Modern, Minimal) | | ✅ |
| Wind direction indicator on the compass rose | | ✅ |
| Extended metrics — Feels Like, Dew Point, Visibility, Air Quality | | ✅ |
| Faster refresh — weather every 10 min, GPS altitude every 10 s | | ✅ |

**Themes:** Dark (charcoal #121212, lime #C8FF00 — the default), Light,
Pure AMOLED black, and Red Light night-vision (red on black, so it
doesn't wreck dark-adapted eyes).

**Premium:** `$0.99/month` with a 7-day free trial
(`banana_premium_monthly`), or `$10` one-time (`banana_premium_lifetime`).
Same unlock either way. Test (debug) builds have Premium unlocked so the
features can be tried before the store products exist; the Play Store
release build never takes that path.

## Android + web — one codebase

The same code builds for Android and for the web. The web app is a full
counterpart, not a stub — but the two platforms have different sensors,
so each feature behaves as follows:

| Feature | Android app | Web app |
| --- | --- | --- |
| Compass heading | Magnetometer (`flutter_compass`) | `DeviceOrientationEvent` — works in mobile browsers; on a desktop PC there is no magnetometer, so the compass shows "unavailable" gracefully instead of a wrong heading |
| Level | Accelerometer (`sensors_plus`) | `DeviceOrientationEvent` (beta/gamma) on mobile browsers; unavailable on desktop |
| Altitude | Barometer when the phone has one, else GPS | GPS only — browsers have no barometer API |
| Coordinates + weather | GPS + Open-Meteo | Browser geolocation + Open-Meteo — works everywhere |
| Premium | Play Billing (`banana_premium_monthly` / `banana_premium_lifetime`) | **Free tier only.** There is no Play Billing in a browser, so the paywall points at the Android app instead of showing buy buttons |

The platform split lives in `lib/services/heading_source.dart` and
`lib/services/tilt_source.dart` (conditional exports: the mobile build
uses the sensor plugins, the web build uses `package:web`).
`flutter analyze` on its own only checks the mobile branch — **always
verify with `flutter build web` too.**

## Declination (True North)

The compass corrects Magnetic North to True North with the **World
Magnetic Model 2025, full degree 12**, computed in pure Dart
(`lib/services/declination.dart`, secular variation applied to the
current date). It was verified against the independent `pygeomag`
implementation (WMM-2025) to within 0.06° at seven cities, and against
published WMM2025 tables (London 1.1° E on 1 Jan 2026). To move to a
newer model (e.g. WMM2030), replace the coefficient numbers only.

## Run it

```bash
flutter pub get
flutter run                 # Android phone / emulator
flutter run -d chrome       # Web, on the PC
flutter analyze             # must be clean
flutter test                # 48 tests
flutter build web --release --base-href /banana-compass/
```

Local APK builds need the Android SDK (not present in every sandbox):
if `flutter build apk` fails for that reason, CI is the build path.

## Push it and get the APK (GitHub)

This folder is a plain copy, **not a git repo** — Antonio creates the
GitHub repo and pushes from WSL himself:

```bash
cd ~/workspace/banana-compass
git init
git add .
git commit -m "Banana Compass v1: compass, level, altimeter, weather (Android + web)"
git branch -M main
git remote add origin https://github.com/iRockaNaNa/banana-compass.git
git push -u origin main
```

Two workflows run on every push to `main`:

- **Build APK** (`.github/workflows/build-apk.yml`): analyze → test →
  `flutter build apk --debug` → the APK is in the run's **Artifacts**
  as `banana-compass-debug-apk`. Download it, install it on a phone,
  try it.
- **Deploy web** (`.github/workflows/deploy-web.yml`): analyze → test →
  `flutter build web` → GitHub Pages. The site goes live at
  `https://irockanana.github.io/banana-compass/` once Pages is enabled
  for the repo (Settings → Pages → Source: GitHub Actions).

If the site moves to a custom domain, drop the `--base-href
/banana-compass/` flag from the deploy workflow (a custom domain serves
from `/`).

## Still to do

- **Real-device test:** install the CI debug APK on a phone and check
  the compass heading (figure-8 to wake the magnetometer), the level,
  the barometer altitude vs a known height, and the weather for the GPS
  city. Also open the web app in Chrome on the phone (heading + level
  through `DeviceOrientationEvent`) and on the PC (compass/level show
  "unavailable", weather + coordinates work).
- **Play Console:** create a $25 developer account, create the app,
  then create the two products exactly as named here:
  `banana_premium_monthly` ($0.99/month — put the 7-day free trial on
  the subscription in Play Console, not in code) and
  `banana_premium_lifetime` ($10 one-time). Until they exist, the
  paywall says "Premium is coming soon" and the free app keeps working.
- **Store listing:** screenshots, description, privacy policy link
  (the company site already has one). App signing in Play Console.
- **Later (backlog, not v1):** Wear OS app, home-screen widgets,
  Flip-to-Align audio/haptic/flashlight, sun path / moon phases,
  weather alerts, iOS Safari compass permission prompt (iOS needs a
  tap to allow `DeviceOrientationEvent` — Android Chrome does not).

## Project layout

```
lib/
  main.dart                  App entry, Nanatech themes, bottom nav
  models/
    app_state.dart           Shared GPS + weather state for all tabs
    settings.dart            Theme, north mode, units, shape (saved)
    weather_data.dart        Open-Meteo current + hourly + air quality
  services/
    compass_service.dart     Smoothed heading + WMM2025 declination
    level_service.dart       Bubble level state (tare, lock)
    altitude_service.dart    Barometer (ISA formula) + GPS fallback
    location_service.dart    GPS with friendly permission errors
    weather_api.dart         Open-Meteo forecast + air quality
    declination.dart         WMM2025 magnetic declination, pure Dart
    premium.dart             Premium rules + entitlement record
    purchase_service.dart    Play Billing + saved entitlement (web: no-op)
    heading_source.dart      Compass source, per platform (conditional)
    tilt_source.dart         Tilt source, per platform (conditional)
    device_orientation_web.dart  Shared DeviceOrientationEvent stream (web)
  utils/
    coordinates.dart         DD / DMS / DDM, mils, cardinal names
    heading_math.dart        Circular heading math (smoothing, arcs)
    tilt_math.dart           Accelerometer / DeviceOrientation tilt math
  widgets/
    compass_rose.dart        CustomPaint rose (Classic/Modern/Minimal)
    hourly_chart.dart        Premium 24-hour temperature chart
  screens/
    compass_screen.dart      Rose, heading, coordinates, altitude
    level_screen.dart        Bubble level dial + tare/lock
    weather_screen.dart      Current + hourly + Premium chart/metrics
    settings_screen.dart     Theme, units, shapes, Premium row
    paywall_screen.dart      Buy/restore (Android) or Android upsell (web)
test/                        48 tests: declination, coordinates, heading
                             math, tilt math, premium, weather data,
                             purchase debug unlock, compass rose widgets
```
