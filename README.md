# FitTracker — Flutter Fitness Activity Tracker

A mobile fitness tracking app built with Flutter for the Mobile Application Development terminal assessment (Scenario 3).

## Features

### Authentication
- User registration with username, email, and password validation
- Login / logout with session persistence via SharedPreferences
- Logout confirmation dialog

### Workout Management (Full CRUD)
- Add workouts with title, type, duration (minutes), date, and notes
- Edit existing workouts
- Delete workouts with confirmation dialog
- Date picker for workout date selection
- Form validation on all fields

### Workout Types (color-coded icons)
| Type | Color |
|------|-------|
| Cardio | Red |
| Strength | Blue |
| Flexibility | Green |
| HIIT | Orange |
| Sports | Purple |
| Other | Grey |

### Filter & Search
- Filter workouts by type (All / Cardio / Strength / Flexibility / HIIT / Sports / Other)
- Filter workouts by specific date via date picker
- Clear filters button when any filter is active
- Empty state shown when no workouts match the filter

### Summary Stats
- Total workout count, total minutes, and total hours displayed on a summary card

### Exercise Tips (REST API)
- Fetches exercise data from the free [wger REST API](https://wger.de/api/v2/exercise/) — no API key required
- Displays exercise name and description (HTML stripped)
- Shows "No description available." when description is empty
- Error state with retry button on network failure
- Manual refresh button in app bar

### Profile
- View current username and email
- Edit and save username / email
- Changes persist to SQLite and SharedPreferences

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter / Material 3 |
| Local DB | SQLite via `sqflite` |
| Session | `shared_preferences` |
| HTTP | `http` package |
| Date formatting | `intl` |

## REST API

**Base URL:** `https://wger.de/api/v2`

| Endpoint | Usage |
|----------|-------|
| `GET /exercise/?format=json&language=2&limit=10` | Fetch English exercises for tips screen |
| `GET /exercisecategory/?format=json` | Fetch exercise categories |

No authentication or API key required.

## Project Structure

```
fitness_tracker/
├── android/app/src/main/AndroidManifest.xml   # Internet permission
├── pubspec.yaml
└── lib/
    ├── main.dart                  # App entry point, session check
    ├── models/models.dart         # User & Workout data models
    ├── db/db_helper.dart          # SQLite CRUD operations
    ├── services/api_service.dart  # wger REST API calls
    └── screens/
        ├── login_screen.dart
        ├── register_screen.dart
        ├── home_screen.dart       # Workout list + filter + bottom nav
        ├── workout_form_screen.dart
        ├── exercise_tips_screen.dart
        └── profile_screen.dart
```

## Dependencies

```yaml
sqflite: ^2.3.0        # SQLite database
path: ^1.8.3           # DB path helper
shared_preferences: ^2.2.2  # Session storage
http: ^1.2.0           # REST API calls
intl: ^0.19.0          # Date formatting
```

## Setup

```bash
flutter pub get
flutter run
```

> Requires Android emulator or physical device. Internet permission is declared in `AndroidManifest.xml`.
