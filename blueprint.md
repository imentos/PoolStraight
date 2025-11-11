Of course. Here is a detailed blueprint and a series of LLM prompts for building the Billiard Straight-Strike Training App.

***

## Project Blueprint: Billiard Straight-Strike Training App

This blueprint breaks the project into logical phases, which are then decomposed into smaller, actionable steps. Each step is designed to be a self-contained unit of work that can be implemented and tested incrementally.

### Phase 1: Application Foundation & Camera Integration
The goal is to get a live camera feed showing within the app's UI.

*   **Chunk 1.1: Project & UI Shell**
    *   **Step 1.1.1:** Create a new, single-view SwiftUI iOS application in Xcode.
    *   **Step 1.1.2:** Build the main content view with a placeholder for the camera feed and a "Start/Stop" button. State will be managed to toggle between a "Ready" and "Active" session.

*   **Chunk 1.2: Live Camera Feed**
    *   **Step 1.2.1:** Create a `CameraService` class using `AVFoundation` to configure and manage a capture session from the front-facing camera.
    *   **Step 1.2.2:** Create a `CameraView` using `UIViewControllerRepresentable` to wrap a `UIViewController` that displays the `AVCaptureVideoPreviewLayer` from the `CameraService`.
    *   **Step 1.2.3:** Integrate the `CameraView` into the main SwiftUI view, replacing the placeholder.

### Phase 2: Pose Estimation & Overlay Foundation
The goal is to detect key body points from the camera feed and prepare to draw them on the screen.

*   **Chunk 2.1: Pose Detection Engine**
    *   **Step 2.1.1:** Integrate the MediaPipe framework into the Xcode project.
    *   **Step 2.1.2:** Create a `PoseEstimator` service that receives video frames (`CVPixelBuffer`) from the `CameraService`.
    *   **Step 2.1.3:** Implement the logic to process the frames using MediaPipe's Pose Landmarker and extract the coordinates for the right elbow and right wrist.
    *   **Step 2.1.4:** Establish a delegate or callback mechanism to send the detected landmark data back to the main view model.

*   **Chunk 2.2: Visual Overlay System**
    *   **Step 2.2.1:** Create a transparent SwiftUI `OverlayView` that will be superimposed on top of the `CameraView`.
    *   **Step 2.2.2:** The `OverlayView` will accept an array of detected points and a geometry proxy to correctly scale and position the drawings.
    *   **Step 2.2.3:** Implement the drawing logic to render circles for the detected elbow and wrist points.
    *   **Step 2.2.4:** Add a fixed, vertical center line to the `OverlayView` for alignment reference.

### Phase 3: Alignment Logic & Real-Time Feedback
The goal is to calculate the player's alignment and provide instant visual and audio feedback.

*   **Chunk 3.1: Core Alignment Calculation**
    *   **Step 3.1.1:** Create an `AlignmentLogic` utility that takes the coordinates of shoulder, elbow (optional), wrist, and head points.
    *   **Step 3.1.2:** Implement functions to calculate arm angle relative to vertical center line and head tilt angle.
    *   **Step 3.1.3:** Determine alignment status (`aligned`, `misaligned`, `notDetected`) based on arm angle and head tilt thresholds.
    *   **Step 3.1.4:** Add configurable sensitivity levels (beginner/intermediate/advanced) with appropriate thresholds for both arm and head alignment.

*   **Chunk 3.2: Dynamic Visual Feedback**
    *   **Step 3.2.1:** Enhance the `OverlayView` to draw lines connecting the arm points (shoulder→elbow→wrist) and head level indicator.
    *   **Step 3.2.2:** The color of arm lines should change based on alignment (green for aligned, red for misaligned).
    *   **Step 3.2.3:** Head tilt indicator should show cyan for level head, orange for tilted head.
    *   **Step 3.2.4:** Implement detection mode indicators showing "2-POINT", "3-POINT", or "3-POINT+HEAD" configurations.
    *   **Step 3.2.5:** Add visual feedback for "Position not detected" when required landmarks are not found.

*   **Chunk 3.3: Audio Feedback**
    *   **Step 3.3.1:** Create an `AudioService` to manage and play sound effects.
    *   **Step 3.3.2:** Preload two sounds: a positive confirmation for alignment and a short alert for misalignment.
    *   **Step 3.3.3:** Trigger the appropriate sound effect from the view model whenever the alignment status changes.

### Phase 4: Final Assembly & Polish
The goal is to connect all components and handle final configuration.

*   **Chunk 4.1: Tying It All Together**
    *   **Step 4.1.1:** Ensure the "Start/Stop" button correctly starts and stops the camera session and pose estimation processing.
    *   **Step 4.1.2:** Create a central `ContentViewModel` to manage state from all services (Camera, Pose, Audio) and provide it to the SwiftUI views.

*   **Chunk 4.2: Project Configuration**
    *   **Step 4.2.1:** Lock the application's orientation to portrait mode only.
    *   **Step 4.2.2:** Add necessary permissions (e.g., Camera Usage Description) to the `Info.plist`.
    *   **Step 4.2.3:** Add placeholder sound files to the project assets.

***

## Prompts for Code-Generation LLM

Here is the series of prompts to generate the code for the project, step by step.

### Prompt 1: Basic App Structure & UI

```text
Create a new iOS application using SwiftUI.

The main view, `ContentView`, should contain:
1. A `ZStack` as the root element.
2. A black `Color` view as the background to simulate a camera feed placeholder.
3. A `VStack` containing a "Start Practice" `Button` at the bottom.
4. The button should toggle a `@State` variable `isSessionActive` between `true` and `false`.
5. The button's label should change to "Stop Practice" when `isSessionActive` is `true`.
6. Use large, readable fonts and padding for the button.```

### Prompt 2: Camera Service with AVFoundation

```text
Create a Swift class named `CameraService`.

This class should:
1. Conform to `NSObject` and be an `ObservableObject`.
2. Use `AVFoundation` to set up an `AVCaptureSession`.
3. Configure the session to use the front-facing camera (`.builtInWideAngleCamera`) as the video input.
4. Configure a `AVCaptureVideoDataOutput` to capture video frames.
5. Set the output's delegate to the `CameraService` itself.
6. Create a `AVCaptureVideoPreviewLayer` from the session.
7. Have public methods `startSession()` and `stopSession()`.
8. Create a delegate protocol `CameraServiceDelegate` with a method `didOutput(sampleBuffer: CVPixelBuffer)`. The `CameraService` will have a delegate property to notify a listener about new frames.
9. Make `CameraService` conform to `AVCaptureVideoDataOutputSampleBufferDelegate` and call its own delegate method from within `captureOutput`.
```

### Prompt 3: Camera View Representable

```text
Create a SwiftUI `UIViewRepresentable` named `CameraView`.

This view should:
1. Hold an instance of `AVCaptureSession`.
2. In `makeUIView`, create a `UIView`.
3. Create an `AVCaptureVideoPreviewLayer` using the session, set its `videoGravity` to `.resizeAspectFill`, and add it as a sublayer to the view's layer.
4. In `updateUIView`, ensure the preview layer's frame matches the view's bounds. This is crucial for handling layout changes.
```

### Prompt 4: Integrate Camera Feed into ContentView

```text
Refactor `ContentView` to display the live camera feed.

1. Create a `@StateObject` property for the `CameraService`.
2. Replace the black `Color` background in the `ZStack` with the `CameraView`, passing it the `cameraService.session`.
3. Modify the "Start/Stop" button's action to call `cameraService.startSession()` and `cameraService.stopSession()` when toggling the `isSessionActive` state.
4. Add an `.onAppear` modifier to the `ZStack` to request camera permissions and configure the camera service when the view first appears.
5. Make sure to add the `NSCameraUsageDescription` key to the `Info.plist`.
```

### Prompt 5: Pose Estimator Service Stub

```text
Create a Swift class named `PoseEstimator`.

This class will be responsible for pose detection using MediaPipe. For now, create a stub:
1. It should have a delegate protocol `PoseEstimatorDelegate` with a method `didDetect(landmarks: [CGPoint])`.
2. It should have a public delegate property of type `PoseEstimatorDelegate?`.
3. It should have a public method `processFrame(_ buffer: CVPixelBuffer)`.
4. Inside `processFrame`, for now, generate mock `CGPoint` data for an elbow and wrist (e.g., `[CGPoint(x: 0.4, y: 0.6), CGPoint(x: 0.4, y: 0.8)]`) and call the delegate method with this data. This allows us to build the UI before the actual ML integration.
```

### Prompt 6: Connect Camera to Pose Estimator

```text
Integrate the `PoseEstimator` with the `CameraService`.

1. In `ContentView`, create a `@StateObject` for the `PoseEstimator`.
2. Make `ContentView` conform to both `CameraServiceDelegate` and `PoseEstimatorDelegate`.
3. In `.onAppear`, set `contentView` as the delegate for both the `cameraService` and `poseEstimator` instances.
4. Implement `didOutput(sampleBuffer:)`: call `poseEstimator.processFrame(sampleBuffer)`.
5. Implement `didDetect(landmarks:)`: store the received points in a `@State` variable, e.g., `@State private var detectedPoints: [CGPoint] = []`.
```

### Prompt 7: Overlay View for Drawing

```text
Create a new SwiftUI view named `OverlayView`.

This view will draw the detected points and lines.
1. It should accept two properties: `detectedPoints` (`[CGPoint]`) and `geometryProxy` (`GeometryProxy`).
2. The body should be a `Canvas`.
3. Inside the canvas, iterate through the `detectedPoints`. For each point, calculate its absolute position using the `geometryProxy.size` (the points are normalized).
4. Draw a green circle at the calculated position for each point.
5. Draw a green line connecting the first and second points if they exist.
6. Add another property `alignmentStatus` (of a new enum type `AlignmentStatus` with cases `.aligned`, `.misaligned`, `.notDetected`). The color of the line and points should be green for `.aligned` and red for `.misaligned`.
```

### Prompt 8: Integrate Overlay View

```text
Add the `OverlayView` to `ContentView`.

1. Wrap the `ZStack`'s content in a `GeometryReader`.
2. Place the `OverlayView` inside the `ZStack`, on top of the `CameraView`.
3. Pass the `detectedPoints` state variable and the `geometryProxy` from the `GeometryReader` to the `OverlayView`.
4. Introduce the `AlignmentStatus` enum and a `@State` variable for it in `ContentView`. For now, hardcode it to `.aligned` to test the drawing.
```

### Prompt 9: Alignment Calculation Logic

```text
Create a Swift struct named `AlignmentLogic`.

This struct will contain the angle calculation logic.
1. Create a static function `calculateAlignment(points: [CGPoint], centerLineX: CGFloat) -> AlignmentStatus`. The `centerLineX` is the normalized x-coordinate of the center line (0.5).
2. The function should first check if there are at least two points. If not, return `.notDetected`.
3. Get the elbow (first point) and wrist (second point).
4. Calculate the angle of the line formed by these two points. `atan2(wrist.y - elbow.y, wrist.x - elbow.x)`.
5. Calculate the angle of the vertical center line, which is -π/2 radians (-90 degrees).
6. Find the absolute difference between the two angles.
7. Convert the difference to degrees.
8. If the absolute deviation is less than or equal to 5 degrees, return `.aligned`. Otherwise, return `.misaligned`.
```

### Prompt 10: Use Alignment Logic

```text
Update `ContentView` to use the `AlignmentLogic`.

1. Remove the hardcoded alignment status.
2. In the `didDetect(landmarks:)` delegate method, after updating the `detectedPoints`, call the `AlignmentLogic.calculateAlignment` function.
3. Update the `@State` variable for the alignment status with the result. This will automatically update the `OverlayView`'s colors in real-time.
```

### Prompt 11: Add Fixed Center Line

```text
Update `OverlayView` to include the fixed center reference line.

1. Inside the `Canvas`, before drawing the points, draw a vertical line.
2. The line should be at the horizontal center of the view's frame.
3. Use a `StrokeStyle` to make the line dashed and white so it's visible but not distracting.
```

### Prompt 12: Audio Feedback Service

```text
Create a Swift class `AudioService`.

1. Import `AVFoundation`.
2. Create two private `AVAudioPlayer` properties, one for the alignment sound and one for the misalignment sound.
3. Create an `init()` method that loads two sound files from the main bundle (`aligned.wav`, `misaligned.wav`) and prepares them for playing. Handle potential errors.
4. Create two public methods: `playAlignmentSound()` and `playMisalignmentSound()`.
5. Add placeholder `.wav` files to your project assets to avoid crashes.
```

### Prompt 13: Integrate Audio Feedback

```text
Integrate the `AudioService` into `ContentView`.

1. Add a `@StateObject` property for the `AudioService`.
2. In the `didDetect(landmarks:)` delegate method, after calculating the new alignment status, compare it to the previous status.
3. If the status has changed, call the appropriate method on the `audioService`.
    - If it changes to `.aligned`, call `playAlignmentSound()`.
    - If it changes to `.misaligned`, call `playMisalignmentSound()`.
4. This ensures sounds only play on a state change, not continuously on every frame.
```

### Prompt 14: Implement Real MediaPipe Pose Detection

```text
Replace the stub in `PoseEstimator` with actual MediaPipe logic.

1. Add the `GoogleGenerativeAI` Swift Package to the project.
2. In `PoseEstimator`, import the library.
3. Set up the MediaPipe `PoseLandmarker`. You will need to add a model file (e.g., `pose_landmarker.task`) to your project.
4. In the `processFrame` method:
    - Convert the `CVPixelBuffer` to a `MPImage`.
    - Call the `poseLandmarker.detect` method.
    - In the result callback, extract the normalized coordinates for the `.rightElbow` and `.rightWrist` landmarks.
    - Check for the visibility of these landmarks. If either is not sufficiently visible (e.g., visibility < 0.5), call the delegate with an empty array.
    - Otherwise, call the delegate with the `[CGPoint]` for the elbow and wrist.
5. This replaces the mock data with real ML-driven landmark detection.
```

### Prompt 15: Add "Not Detected" Visual Indicator

```text
Update `ContentView` and `OverlayView` to handle the `.notDetected` state.

1. In `OverlayView`, if the `alignmentStatus` is `.notDetected`, do not draw the points or the connecting line.
2. In `ContentView`, add a `Text("Position Not Detected")` view inside the `ZStack`.
3. Set its font, add padding, and give it a semi-transparent background.
4. Use the `alignmentStatus` state to show this text view only when the status is `.notDetected`.
```

### Prompt 16: Final Project Configuration

```text
Finalize the project settings.

1. In the project's target settings, under "General" -> "Deployment Info", check the "Portrait" device orientation only.
2. Ensure the `NSCameraUsageDescription` in `Info.plist` has a user-friendly message, such as "This app uses the camera to help you practice your billiard strike alignment."
3. Review the code and add comments where necessary. Ensure the start/stop logic correctly pauses and resumes both the `AVCaptureSession` and any processing loops.
```