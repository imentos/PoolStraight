# PoolStraight - Billiard Straight-Strike Training App

An iOS app designed for casual or beginner billiard players to practice straight strikes with real-time pose detection and alignment feedback.

## Features

- **Real-time Pose Detection**: Track elbow, wrist, and cue tip using pose estimation
- **Visual Feedback**: Live overlay lines with color indicators (green for aligned, red for misaligned)
- **Audio Feedback**: Instantaneous audio alerts for alignment status
- **Front-facing Camera**: Mirror-style view for natural practice positioning
- **Portrait Mode**: Optimized for portrait orientation practice sessions

## Current Status

✅ **Phase 1 Complete - Application Foundation & Camera Integration**
- Live camera feed with front-facing camera
- Start/Stop practice session controls
- Camera permissions and session management
- SwiftUI-based user interface

🚧 **Coming Next - Phase 2: Pose Estimation & Overlay Foundation**
- MediaPipe integration for pose detection
- Visual overlay system for alignment feedback
- Real-time landmark tracking

## Technical Stack

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI
- **Camera**: AVFoundation
- **Pose Detection**: MediaPipe (planned)
- **Language**: Swift 5.0

## Project Structure

```
PoolStraight/
├── PoolStraight.xcodeproj/     # Xcode project files
└── PoolStraight/
    ├── PoolStraightApp.swift   # App entry point
    ├── ContentView.swift       # Main UI with camera integration
    ├── CameraService.swift     # AVFoundation camera management
    ├── CameraView.swift        # SwiftUI camera preview wrapper
    ├── Info.plist             # App configuration & permissions
    └── Assets.xcassets/        # App assets and icons
```

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- iPhone/iPad with front-facing camera
- Camera permissions

## Installation

1. Clone this repository
2. Open `PoolStraight.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project

## Usage

1. Launch the app
2. Grant camera permissions when prompted
3. Tap "Start Practice" to begin camera session
4. Position yourself in front of the camera for billiard practice
5. Tap "Stop Practice" to end the session

## Development Roadmap

### Phase 1: ✅ Application Foundation & Camera Integration
- [x] Basic SwiftUI app structure
- [x] Live camera feed integration
- [x] Session start/stop controls
- [x] Camera permissions setup

### Phase 2: 🚧 Pose Estimation & Overlay Foundation
- [ ] MediaPipe integration
- [ ] Pose landmark detection (elbow, wrist, cue tip)
- [ ] Visual overlay system
- [ ] Real-time coordinate tracking

### Phase 3: 📋 Alignment Logic & Real-Time Feedback
- [ ] Alignment calculation algorithms
- [ ] Dynamic visual feedback (colored lines)
- [ ] Audio feedback system
- [ ] Real-time performance optimization

### Phase 4: 📋 Final Assembly & Polish
- [ ] Complete feature integration
- [ ] Performance optimization
- [ ] UI/UX refinements
- [ ] Testing and bug fixes

## Contributing

This project follows the detailed blueprint outlined in the project documentation. Each phase is broken down into specific chunks and steps for systematic development.

## License

[Add your preferred license here]

## Target Users

- Casual billiard players
- Beginners learning proper strike alignment
- Right-handed players (MVP scope)

---

*Built with SwiftUI for iOS*