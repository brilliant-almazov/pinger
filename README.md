# Pinger

[![CI](https://github.com/brilliant-almazov/pinger/actions/workflows/ci.yml/badge.svg)](https://github.com/brilliant-almazov/pinger/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/brilliant-almazov/pinger/graph/badge.svg)](https://codecov.io/gh/brilliant-almazov/pinger)

macOS menu bar utility for monitoring internet connection.

## Features

- Real-time ping monitoring in menu bar
- Multiple ping targets (Google DNS, Cloudflare, custom)
- Visual status indicators (🟢 🟡 🔴)
- Ping history
- Configurable interval and thresholds
- Pause/resume functionality

## Screenshots

<p align="center">
  <img src="docs/screenshots/menubar.png" alt="Menu Bar" width="200"/>
</p>

<p align="center">
  <img src="docs/screenshots/menu.png" alt="Popup Menu" width="300"/>
  <img src="docs/screenshots/settings.png" alt="Settings" width="300"/>
</p>

## Requirements

- macOS 14.0+
- Xcode 16.0+

## Building

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open and build:
   ```bash
   open Pinger.xcodeproj
   ```

## Development

Project uses XcodeGen for project configuration. Edit `project.yml` to modify project settings.

### Structure

```
Pinger/
├── Sources/
│   ├── App/        # App entry point, AppDelegate
│   ├── Models/     # Data models
│   ├── Services/   # Business logic
│   ├── Views/      # SwiftUI views
│   └── Utils/      # Utilities
├── Resources/      # Assets, Info.plist
PingerTests/        # Unit tests
PingerUITests/      # UI tests
```

## License

MIT
