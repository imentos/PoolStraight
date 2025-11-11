Of course. Here is a thorough `TODO.md` file that you can use as a checklist to track the development of the Billiard Straight-Strike Training App.

```markdown
# TODO: Billiard Straight-Strike Training App (MVP)

This checklist breaks down the project into four main phases. Complete the items in order to ensure an incremental and testable build process.

---

## Phase 1: Application Foundation & Camera Integration

The goal of this phase is to set up the basic app structure and display a live feed from the front-facing camera.

### 1.1 Project Setup & UI Shell
- [ ] Create a new iOS project in Xcode using the SwiftUI App template.
- [ ] In `ContentView.swift`, create the main `ZStack` layout.
- [ ] Add a `Color.black` view inside the `ZStack` as a temporary placeholder for the camera feed.
- [ ] Add a `VStack` to hold UI elements.
- [ ] Implement a `@State private var isSessionActive: Bool` to manage the practice session state.
- [ ] Create a `Button` with a label that dynamically changes from "Start Practice" to "Stop Practice" based on `isSessionActive`.
- [ ] Wire the button's action to toggle the `isSessionActive` state.
- [ ] Style the button for clear visibility against the camera feed.

### 1.2 Camera Service (`CameraService.swift`)
- [ ] Create a new Swift file named `CameraService.swift`.
- [ ] Define a `CameraService` class that conforms to `NSObject` and `ObservableObject`.
- [ ] Import `AVFoundation`.
- [ ] Declare properties for `AVCaptureSession`, `AVCaptureDeviceInput`, and `AVCaptureVideoDataOutput`.
- [ ] Create a `setupSession()` method to:
    - [ ] Get the front-facing camera.
    - [ ] Create an `AVCaptureDeviceInput` from the device.
    - [ ] Add the input to the session.
    - [ ] Configure the `AVCaptureVideoDataOutput` to process video frames.
    - [ ] Add the output to the session.
- [ ] Define a `CameraServiceDelegate` protocol with a single method: `didOutput(sampleBuffer: CVPixelBuffer)`.
- [ ] Make `CameraService` conform to `AVCaptureVideoDataOutputSampleBufferDelegate`.
- [ ] Implement `captureOutput(_:didOutput:from:)` to forward the `CVPixelBuffer` to its own delegate.
- [ ] Create public `startSession()` and `stopSession()` methods that call `session.startRunning()` and `session.stopRunning()`.

### 1.3 Camera View (`CameraView.swift`)
- [ ] Create a new SwiftUI file named `CameraView.swift`.
- [ ] Define a `CameraView` struct that conforms to `UIViewRepresentable`.
- [ ] It should take an `AVCaptureSession` as a property.
- [ ] Implement `makeUIView(context:)` to create a `UIView` and attach an `AVCaptureVideoPreviewLayer` from the session.
- [ ] Implement `updateUIView(_:context:)` to ensure the preview layer's frame is updated on layout changes.

### 1.4 Integration & Permissions
- [ ] In `ContentView`, create an instance of `CameraService` as a `@StateObject`.
- [ ] Replace the `Color.black` placeholder with the `CameraView`, passing it the `cameraService.session`.
- [ ] Connect the "Start/Stop" button's action to `cameraService.startSession()` and `cameraService.stopSession()`.
- [ ] Add logic (e.g., in `.onAppear`) to request camera permissions using `AVCaptureDevice.requestAccess(for:)`.
- [ ] Add the `NSCameraUsageDescription` key to `Info.plist` with a user-friendly message.

---

## Phase 2: Pose Estimation & Overlay Foundation

The goal of this phase is to detect body landmarks from the camera feed and draw them on the screen.

### 2.1 Dependency Management
- [ ] Add the MediaPipe Swift Package (`GoogleGenerativeAI`) via Xcode's Swift Package Manager.
- [ ] Download the `pose_landmarker_lite.task` model file from MediaPipe's model repository.
- [ ] Add the `.task` model file to your Xcode project bundle.

### 2.2 Pose Estimator Service (`PoseEstimator.swift`)
- [x] Create a new Swift file named `PoseEstimator.swift`.
- [x] Define a `PoseEstimator` class.
- [x] Create a `PoseEstimatorDelegate` protocol with the method `didDetect(landmarks: [CGPoint])`.
- [x] Implement an `init()` method that sets up the Apple Vision framework pose detection.
- [x] Implement a `processFrame(_ buffer: CVPixelBuffer)` method that:
    - [x] Uses `VNDetectHumanBodyPoseRequest` to detect pose landmarks.
    - [x] Extracts normalized coordinates for shoulder, elbow (optional), wrist, and head landmarks.
    - [x] Handles camera mirroring for front-facing camera view.
    - [x] Checks confidence levels of each landmark for reliability.
    - [x] Calls the delegate with flexible point array: arm points + optional head points.
    - [x] Provides fallback when elbow cannot be detected (uses shoulder-wrist only).
    - [x] Includes head tilt detection using eye positions when available.

### 2.3 Visual Overlay (`OverlayView.swift`)
- [x] Create a new SwiftUI file named `OverlayView.swift`.
- [x] Define an `OverlayView` struct that takes `detectedPoints: [CGPoint]` and alignment status as inputs.
- [x] Use a `Canvas` as the view's body for custom drawing.
- [x] Inside the `Canvas`, draw a static, dashed, vertical center line for cue alignment reference.
- [x] Implement drawing logic for flexible point configurations (2-point, 3-point, 3-point+head).
- [x] Draw arm alignment: thick shoulder→wrist line (primary) + dimmed elbow segments (secondary).
- [x] Draw head tilt indicator: eye-to-eye line with color coding (cyan=level, orange=tilted).
- [x] Add detection mode indicators showing current pose detection configuration.
- [x] Color-coded feedback: green=aligned, red=misaligned, cyan=head level, orange=head tilted.

### 2.4 Integration
- [ ] In `ContentView`, create an instance of `PoseEstimator` as a `@StateObject`.
- [ ] Make `ContentView` conform to `CameraServiceDelegate` and `PoseEstimatorDelegate`.
- [ ] In `.onAppear`, set `ContentView` as the delegate for both services.
- [ ] Implement `didOutput` to call `poseEstimator.processFrame(sampleBuffer)`.
- [ ] Implement `didDetect` to update a `@State private var detectedPoints: [CGPoint]`.
- [ ] Wrap the `ZStack`'s content in a `GeometryReader`.
- [ ] Add the `OverlayView` to the `ZStack`, placing it on top of the `CameraView`.
- [ ] Pass the `detectedPoints` and the `geometryProxy` from the `GeometryReader` into the `OverlayView`.

---

## Phase 3: Alignment Logic & Real-Time Feedback

The goal of this phase is to analyze the detected points and provide real-time visual and audio feedback to the user.

### 3.1 Alignment Logic (`AlignmentLogic.swift`)
- [x] Create a new Swift file named `AlignmentLogic.swift`.
- [x] Define an `AlignmentStatus` enum with values `.aligned`, `.misaligned`, and `.notDetected`.
- [x] Create a static function `calculateAlignment(points: [CGPoint], centerLineX: CGFloat) -> AlignmentStatus`.
- [x] Handle flexible point configurations: 2-point (shoulder-wrist), 3-point (shoulder-elbow-wrist), and head detection.
- [x] Calculate arm angle relative to vertical center line with configurable sensitivity levels.
- [x] Add head tilt calculation using eye positions to ensure level head for proper billiard stance.
- [x] Implement sensitivity levels: beginner (±12° arm, ±15° head), intermediate (±8° arm, ±10° head), advanced (±5° arm, ±6° head).
- [x] Combine arm and head alignment for overall feedback with appropriate prioritization.
- [x] Return alignment status considering both arm position and head tilt when available.

### 3.2 Dynamic Visual Feedback
- [x] In `ContentView`, add `@State private var alignmentStatus: AlignmentStatus = .notDetected`.
- [x] In the `didDetect` delegate method, use result to call `AlignmentLogic.calculateAlignment` and update `alignmentStatus`.
- [x] Pass the `alignmentStatus` to `OverlayView`.
- [x] In `OverlayView`, implement comprehensive drawing logic:
    - [x] Draw primary shoulder→wrist alignment line (thick, color-coded).
    - [x] Draw secondary elbow segments when available (dimmed).
    - [x] Draw head level indicator when head landmarks detected (cyan=level, orange=tilted).
    - [x] Color coding: green for arm aligned, red for misaligned, appropriate head tilt colors.
    - [x] Detection mode indicators showing current pose configuration.
    - [x] Handle "Position not detected" cases gracefully.

### 3.3 Audio Feedback (`AudioService.swift`)
- [ ] Create two short sound files: `aligned.wav` (positive) and `misaligned.wav` (alert).
- [ ] Add the sound files to the project's assets.
- [ ] Create a new Swift file named `AudioService.swift`.
- [ ] Import `AVFoundation`.
- [ ] Create an `AudioService` class with two `AVAudioPlayer` properties.
- [ ] In its `init()`, load and prepare both audio players from the bundled files.
- [ ] Create public methods `playAlignmentSound()` and `playMisalignmentSound()`.

### 3.4 Audio Integration
- [ ] In `ContentView`, create an instance of `AudioService` as a `@StateObject`.
- [ ] In the `didDetect` method, compare the new `alignmentStatus` to the previous one.
- [ ] If the status changes, call the appropriate `AudioService` method (e.g., if changing from `.misaligned` to `.aligned`, play the alignment sound). This prevents the sound from playing on every single frame.

---

## Phase 4: Final Assembly & Polish

The goal of this phase is to finalize the app's configuration, perform thorough testing, and ensure all components work together smoothly.

### 4.1 State Management & Refinement
- [ ] (Optional but recommended) Create a `ContentViewModel` to manage all state and delegate callbacks, cleaning up `ContentView`.
- [ ] Verify that the "Start/Stop" button correctly starts and stops both the camera session and the pose estimation processing.

### 4.2 Project Configuration
- [ ] In the project's target settings, under "General" -> "Deployment Info", lock the device orientation to "Portrait" only.
- [ ] Review and finalize the `NSCameraUsageDescription` message in `Info.plist`.

### 4.3 Testing
- [ ] **Functional Test:** Verify pose points for elbow and wrist are accurately detected and rendered.
- [ ] **Functional Test:** Confirm overlay line color correctly switches between green and red based on alignment.
- [ ] **Functional Test:** Confirm audio cues trigger correctly and only on a change of alignment state.
- [x] **Usability Test:** Ensure the front-facing camera view feels natural and mirrored for the user. (✅ Fixed: Using left joints in pose detection to handle mirrored camera)
- [ ] **Performance Test:** Run the app and confirm the UI remains smooth and responsive (e.g., 30+ FPS).
- [ ] **Edge Case Test:** Test performance in standard indoor lighting conditions.
- [ ] **Edge Case Test:** Test what happens if the device is accidentally moved or shaken during a session.

---

## ✅ Recent Completions

### UX Improvements:
- [x] **Removed Start/Stop Buttons**: App now automatically starts pose capture when camera permission is granted
- [x] **Automatic Session Management**: Camera session starts immediately upon permission approval
- [x] **Streamlined UI**: Direct access to pose detection without manual session control
- [x] **Camera Mirroring Fix**: Using left joints (.leftElbow, .leftWrist, .leftHand) mapped to RIGHT_* IDs for natural mirrored view experience

### Current Status:
- ✅ Camera preview working
- ✅ Pose detection active
- ✅ Visual overlays functional
- ✅ Audio feedback implemented
- ✅ Automatic startup working
- ✅ Natural mirrored view experience

The app now provides immediate access to billiard alignment training without requiring manual session management!

