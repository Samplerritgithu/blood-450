# 📱 Flutter Project Setup Guide

## 🎯 Complete Setup Instructions

---

## STEP 1: Install Flutter SDK

### Windows Installation:

1. **Download Flutter SDK:**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable release
   - Extract to: `C:\src\flutter` (or your preferred location)

2. **Add Flutter to PATH:**
   ```powershell
   # Open PowerShell as Administrator
   # Add Flutter bin to PATH
   $env:Path += ";C:\src\flutter\bin"
   
   # Make it permanent
   [System.Environment]::SetEnvironmentVariable('Path', $env:Path, [System.EnvironmentVariableTarget]::User)
   ```

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

4. **Install Missing Dependencies:**
   ```bash
   # If Android is missing
   flutter doctor --android-licenses
   
   # Accept all licenses
   ```

---

## STEP 2: Create Flutter Project

### Option A: Inside Current Workspace (Recommended)

```bash
# Navigate to AYH folder
cd C:\Users\Avs-Mohandas\Desktop\Projects\AYH

# Create Flutter project
flutter create ayh_mobile

# This creates:
# AYH/
# ├── AYH/           ← Django backend
# └── ayh_mobile/    ← Flutter app
```

### Option B: Integrated (Inside Django Folder)

```bash
# Navigate to Django project
cd C:\Users\Avs-Mohandas\Desktop\Projects\AYH\AYH

# Create Flutter project
flutter create mobile

# This creates:
# AYH/AYH/
# ├── careapp/       ← Django
# ├── manage.py      ← Django
# └── mobile/        ← Flutter
```

**I recommend Option A for cleaner separation!**

---

## STEP 3: Open Multi-Root Workspace

### In VS Code/Cursor:

1. **Navigate to:**
   ```
   C:\Users\Avs-Mohandas\Desktop\Projects\AYH\
   ```

2. **Double-click on:**
   ```
   AYH_FullStack.code-workspace
   ```

3. **Your workspace will show:**
   ```
   EXPLORER
   ├── 🐍 Django Backend (API)
   │   ├── careapp/
   │   ├── templates/
   │   └── manage.py
   └── 📱 Flutter Mobile App
       ├── lib/
       ├── android/
       └── pubspec.yaml
   ```

**Perfect! Both projects in one window!** ✅

---

## STEP 4: Install Flutter Dependencies

### In Terminal:

```bash
# Navigate to Flutter project
cd ayh_mobile  # or mobile

# Get dependencies
flutter pub get

# Verify everything works
flutter doctor
```

---

## STEP 5: Set Up Flutter Project Structure

### Recommended Folder Structure:

```
ayh_mobile/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── dio_client.dart
│   │   ├── constants/
│   │   │   ├── colors.dart
│   │   │   ├── strings.dart
│   │   │   └── api_constants.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── helpers.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── donor_profile.dart
│   │   │   ├── blood_request.dart
│   │   │   └── notification.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   └── blood_repository.dart
│   │   └── services/
│   │       ├── auth_service.dart
│   │       └── storage_service.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── admin/
│   │   │   │   ├── admin_dashboard.dart
│   │   │   │   └── create_request_screen.dart
│   │   │   └── donor/
│   │   │       ├── notifications_screen.dart
│   │   │       └── profile_screen.dart
│   │   ├── widgets/
│   │   │   ├── custom_button.dart
│   │   │   ├── blood_group_badge.dart
│   │   │   └── notification_card.dart
│   │   └── providers/
│   │       ├── auth_provider.dart
│   │       └── notification_provider.dart
│   └── routes/
│       └── app_routes.dart
├── android/
├── ios/
└── pubspec.yaml
```

---

## STEP 6: Add Required Packages

### Update `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.4.0                    # HTTP client
  retrofit: ^4.0.0               # Type-safe API
  
  # State Management
  provider: ^6.1.0               # State management
  
  # Local Storage
  shared_preferences: ^2.2.0     # Simple storage
  flutter_secure_storage: ^9.0.0 # Secure token storage
  
  # Navigation
  go_router: ^13.0.0             # Routing
  
  # UI Components
  flutter_svg: ^2.0.0            # SVG support
  cached_network_image: ^3.3.0   # Image caching
  shimmer: ^3.0.0                # Loading effects
  flutter_spinkit: ^5.2.0        # Loading indicators
  
  # Utilities
  intl: ^0.18.0                  # Date formatting
  get_it: ^7.6.0                 # Dependency injection
  logger: ^2.0.0                 # Logging
  freezed_annotation: ^2.4.1     # Code generation
  json_annotation: ^4.8.1        # JSON serialization

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  freezed: ^2.4.1
  json_serializable: ^6.7.0
```

### Install Packages:

```bash
flutter pub get
```

---

## STEP 7: Run Both Projects Simultaneously

### Method 1: Using Built-in Tasks

In VS Code/Cursor:

1. **Press:** `Ctrl + Shift + P`
2. **Type:** `Tasks: Run Task`
3. **Select:**
   - `Django: Start Server` (opens Django in terminal 1)
   - `Flutter: Run` (opens Flutter in terminal 2)

### Method 2: Using Terminals

**Terminal 1 (Django):**
```bash
cd C:\Users\Avs-Mohandas\Desktop\Projects\AYH\AYH
python manage.py runserver
```

**Terminal 2 (Flutter):**
```bash
cd C:\Users\Avs-Mohandas\Desktop\Projects\AYH\ayh_mobile
flutter run
```

### Method 3: Using Launch Configurations

1. **Press:** `F5`
2. **Select:** `🚀 Full Stack: Django + Flutter`
3. **Both will start automatically!**

---

## STEP 8: Configure Flutter for Your API

### Update API Base URL:

Create `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api/';
  
  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:8000/api/';
  
  // For Physical Device (replace with your PC IP)
  // static const String baseUrl = 'http://192.168.1.100:8000/api/';
  
  // Endpoints
  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String notifications = 'notifications/';
  static const String respond = 'respond/';
  static const String bloodRequests = 'blood-requests/';
}
```

---

## 🧪 TESTING

### Test Django API:

```bash
# In Django terminal
python manage.py runserver

# Open browser
http://127.0.0.1:8000/api/
```

### Test Flutter App:

```bash
# In Flutter terminal
flutter run

# Or press F5 in VS Code
```

---

## 🎯 WORKSPACE FEATURES

Your `AYH_FullStack.code-workspace` includes:

### ✅ Multi-Root Workspace
- Django and Flutter in one window
- Separate terminals for each
- Easy switching between projects

### ✅ Tasks
- `Django: Start Server` - Run Django
- `Django: Make Migrations` - Create migrations
- `Django: Migrate` - Apply migrations
- `Flutter: Get Packages` - Install dependencies
- `Flutter: Run` - Run app
- `Flutter: Build APK` - Build release APK

### ✅ Launch Configurations
- `🐍 Django: Run Server` - Debug Django
- `📱 Flutter: Run Debug` - Debug Flutter
- `📱 Flutter: Run Release` - Run release build
- `🚀 Full Stack: Django + Flutter` - Run both simultaneously

### ✅ Recommended Extensions
- Python
- Dart & Flutter
- Django
- Auto Rename Tag
- Prettier

---

## 📱 CONNECTING FLUTTER TO DJANGO

### For Android Emulator:
```dart
baseUrl: 'http://10.0.2.2:8000/api/'
```

### For iOS Simulator:
```dart
baseUrl: 'http://localhost:8000/api/'
```

### For Physical Device:

1. **Find your PC's IP:**
   ```bash
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.100)
   ```

2. **Update Django `settings.py`:**
   ```python
   ALLOWED_HOSTS = ['localhost', '127.0.0.1', '192.168.1.100']
   ```

3. **Run Django:**
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

4. **Use in Flutter:**
   ```dart
   baseUrl: 'http://192.168.1.100:8000/api/'
   ```

---

## 🎨 WORKSPACE LAYOUT

```
┌─────────────────────────────────────────────────────────┐
│ VS Code / Cursor Window                                 │
├─────────────────────────────────────────────────────────┤
│ EXPLORER                                                │
│ ├── 🐍 Django Backend (API)                            │
│ │   ├── careapp/                                       │
│ │   ├── templates/                                     │
│ │   ├── manage.py                                      │
│ │   └── requirements.txt                               │
│ └── 📱 Flutter Mobile App                              │
│     ├── lib/                                           │
│     ├── android/                                       │
│     └── pubspec.yaml                                   │
├─────────────────────────────────────────────────────────┤
│ EDITOR                                                  │
│ - Edit Django files                                    │
│ - Edit Flutter files                                   │
│ - Switch easily between both                           │
├─────────────────────────────────────────────────────────┤
│ TERMINAL 1: Django                                      │
│ $ python manage.py runserver                           │
│ Django server running on http://127.0.0.1:8000         │
├─────────────────────────────────────────────────────────┤
│ TERMINAL 2: Flutter                                     │
│ $ flutter run                                          │
│ Flutter app running on Android emulator                │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ VERIFICATION CHECKLIST

- [ ] Flutter SDK installed
- [ ] `flutter doctor` shows no errors
- [ ] Flutter project created
- [ ] Workspace file opened in VS Code/Cursor
- [ ] Both projects visible in sidebar
- [ ] Can run Django server
- [ ] Can run Flutter app
- [ ] Flutter can connect to Django API

---

## 🚀 QUICK START COMMANDS

```bash
# Open workspace
code AYH_FullStack.code-workspace

# Terminal 1: Start Django
cd AYH
python manage.py runserver

# Terminal 2: Start Flutter
cd ayh_mobile
flutter run
```

---

## 📚 NEXT STEPS

1. ✅ Set up workspace (DONE)
2. ✅ Create Flutter project
3. ⏭️ Install Flutter packages
4. ⏭️ Set up Dio API client
5. ⏭️ Create login screen
6. ⏭️ Implement authentication
7. ⏭️ Build notification screen
8. ⏭️ Connect to Django API

---

**Your development environment is ready for full-stack development!** 🎉
