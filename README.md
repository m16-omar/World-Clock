# 🌍 World Time — Offline-First World Clock & Timezone Converter

A premium, offline-first Flutter application featuring real-time world clocks, offline IANA timezone calculations, future date/time cross-timezone conversions, and an interactive meeting planner.

![Flutter](https://img.shields.io/badge/Flutter-3.38.5-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.4-0175C2?logo=dart)
![Riverpod](https://img.shields.io/badge/Riverpod-3.x-blueviolet)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/offline--first-100%25-success)

---

## ✨ Features

### 📴 100% Offline IANA Timezone Engine
- **Zero API Reliance**: Bundled complete IANA timezone database. Calculations work anywhere, even in airplane mode.
- **Accurate DST Rules**: Computes historical and future Daylight Saving Time status for any date.
- **Day & Night Period Detection**: Displays Morning (🌅), Afternoon (☀️), Evening (🌇), or Night (🌙) with dynamic gradient accents.
- **Work Hours Detection**: Instantly indicates if a time in another zone falls within business hours (9:00 AM – 5:00 PM).

### 🕐 Live World Clocks
- **Local Time Hero Dashboard**: Real-time display of current location, date, UTC offset, and DST indicators.
- **Live Ticker**: World clock cards update synchronously every second.
- **Curated Default Cities**: Pre-loaded with Lagos, New York, London, Tokyo, Dubai, and Sydney.
- **Persistence**: Save, remove, and manage favorite cities locally.

### 🔄 Future Date & Time Converter
- **Base Zone Selector**: Choose any city as the reference point.
- **Date & Time Pickers**: Convert future dates up to 2050 offline.
- **24-Hour Timeline Scrubber**: Slide through hours 0–23 to see instantaneous timezone shifts.
- **Multi-Zone Comparison**: Compare multiple world cities side-by-side.
- **One-Tap Copy**: Quick copy formatted time and date to clipboard.

### ⏰ World Alarms & Local Reminders
- **Location-Aware Alarms**: Set alarms for local time or sync with any international city (e.g. 9:00 AM Tokyo or London time).
- **Exact Scheduling**: Powered by `flutter_local_notifications` with exact time alarms while device is idle.
- **Repeat Options**: Customizable repeat schedules (Every day, Weekdays, Weekends, specific days, or one-off).
- **Upcoming Alarm Countdown**: Dynamic dashboard indicator displaying hours and minutes remaining until next alarm.
- **Notification Test**: Instant trigger button to verify alarm sound and push banner on device.

### 🗺️ Timezone Browser
- **Global Search**: Search by city, country, or IANA timezone identifier.
- **Continent Filters**: Quick-filter chips for Africa, America, Europe, Asia, and Oceania.
- **Quick Save**: Add any location directly to your dashboard.

### ⚙️ Settings & Customization
- **12H / 24H Format**: Seamless switch between 12-hour and 24-hour display modes.
- **Show Seconds Toggle**: Choose whether to display ticking seconds.
- **Themes**: OLED Luxury Dark Mode and Clean Daytime Light Mode.

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/
│   │   └── default_cities.dart          # Curated favorites & world cities catalog
│   ├── notifications/
│   │   └── notification_service.dart    # Exact alarm & notification scheduling
│   ├── storage/
│   │   └── storage_service.dart         # SharedPreferences offline persistence
│   ├── theme/
│   │   └── app_theme.dart               # Outfit & Inter typography, dark/light themes
│   └── timezone/
│       ├── timezone_database.dart       # IANA database initialization & lookup
│       ├── timezone_model.dart          # TimezoneItem data model
│       └── timezone_service.dart        # Conversion, DST, offsets, TimeDayPeriod logic
├── features/
│   ├── alarms/
│   │   ├── models/
│   │   │   └── alarm_model.dart         # Alarm data model & repeat logic
│   │   ├── providers/
│   │   │   └── alarm_provider.dart      # Riverpod 3 Notifier for alarms
│   │   ├── screens/
│   │   │   └── alarms_screen.dart       # World alarms screen & countdown banner
│   │   └── widgets/
│   │       ├── alarm_card.dart          # Alarm card with switch & timezone badge
│   │       └── edit_alarm_sheet.dart    # Time picker, repeat days & location sheet
│   ├── home/
│   │   └── home_screen.dart             # Root IndexedStack bottom navigation
│   ├── settings/
│   │   ├── providers/
│   │   │   └── settings_provider.dart   # Riverpod 3 Notifier for preferences
│   │   └── screens/
│   │       └── settings_screen.dart     # Settings UI
│   ├── time_converter/
│   │   ├── providers/
│   │   │   └── converter_provider.dart  # Riverpod 3 Notifier for converter state
│   │   └── screens/
│   │       └── time_converter_screen.dart # Future converter & timeline slider
│   ├── timezone_browser/
│   │   ├── providers/
│   │   │   └── timezone_browser_provider.dart # Search and continent filter notifiers
│   │   └── screens/
│   │       └── timezone_browser_screen.dart # Searchable catalog
│   └── world_clock/
│       ├── providers/
│       │   └── world_clock_provider.dart # 1s ticker, device timezone, favorites
│       ├── screens/
│       │   └── world_clock_screen.dart   # Main clocks dashboard
│       └── widgets/
│           ├── local_time_hero_card.dart # Local device time hero card
│           └── world_clock_card.dart     # Individual world city card
└── main.dart                            # Entry point with Riverpod & Storage overrides
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.38.5 or higher recommended)
- [Dart SDK](https://dart.dev/get-dart) (3.10.4 or higher)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/m16-omar/World-Clock.git
   cd World-Clock
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the test suite:
   ```bash
   flutter test
   ```

4. Launch the application:
   ```bash
   # On macOS
   flutter run -d macos

   # In Chrome
   flutter run -d chrome

   # On iOS
   flutter run -d ios
   ```

---

## 🧪 Testing

The codebase includes automated unit and widget tests verifying:
- IANA database offline initialization
- DST rule verification (winter vs summer transitions)
- Precise cross-timezone conversions
- TimeDayPeriod categorization
- App initialization and widget rendering

Run tests with:
```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License.
