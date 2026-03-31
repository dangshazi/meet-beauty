# Meet Beauty - AI Makeup Coaching App

An AI-powered makeup learning application that provides personalized tutorials with real-time AR guidance.

## Features

- **Face Analysis**: AI-powered facial feature detection and analysis
- **Personalized Recommendations**: Custom makeup tutorials based on your face shape, skin tone, and lip type
- **AR Tutorial Overlay**: Real-time visual guidance for makeup application
- **Progress Scoring**: Instant feedback on your makeup application

## Tech Stack

- **Flutter** - Cross-platform mobile development
- **Google ML Kit** - Face detection and landmarks
- **Provider** - State management
- **go_router** - Navigation

## Project Structure

```
lib/
  app/                    # App-level configuration
    theme/                # Theme and colors
    app.dart              # Root app widget
    router.dart           # Navigation routes
  core/                   # Core utilities
    constants/
    utils/
    logger/
  features/               # Feature-based modules
    home/                 # Home page
    analysis/             # Face analysis feature
    recommendation/       # Makeup recommendations
    tutorial/             # AR tutorial feature
    result/               # Scoring and results
  services/               # Infrastructure services
    camera/               # Camera management
    facemesh/             # Face detection
    overlay/              # AR overlay rendering
  shared/                 # Shared components
    models/               # Data models
    widgets/              # Reusable widgets
    config/               # App configuration
```

## Getting Started

### Prerequisites

- Flutter SDK 3.11+
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Run integration tests (requires Android emulator or device):
   ```bash
   flutter test integration_test/ -d <device-id>
   ```
   See [TESTING.md](./TESTING.md) for full testing guide.

## Development Status

This project is currently in MVP development phase. See the following documents for details:

- [PRD-AI化妆教学APP.md](./PRD-AI化妆教学APP.md) - Product Requirements Document
- [技术方案-MVP-AI化妆教学APP.md](./技术方案-MVP-AI化妆教学APP.md) - Technical Architecture
- [开发任务清单-AI化妆教学APP.md](./开发任务清单-AI化妆教学APP.md) - Development Task List
- [TESTING.md](./TESTING.md) - Testing Guide
- [ANDROID_BUILD.md](./ANDROID_BUILD.md) - Android Build Guide

## License

Private project - All rights reserved
