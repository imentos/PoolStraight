Billiard Straight-Strike Training App – MVP Specification
1. Overview

An iOS app designed for casual or beginner billiard players to practice straight strikes. The app provides real-time visual and audio feedback to help players align their elbow → wrist → cue tip with a fixed center line toward the target pocket.

2. Target User

Casual or beginner billiard players

Right-handed only (MVP)

3. Core Features
3.1 Real-Time Pose Detection

Track elbow, wrist, and cue tip using pose estimation.

Feedback is given only when all key points are visible.

Front-facing camera used for a mirror-style view.

Detection starts automatically when the live camera feed opens.

3.2 Visual Feedback

Overlay lines: elbow → wrist → cue tip.

Fixed center line overlay on the table for aiming.

Color indicators:

Green line when aligned within ±5° deviation

Red line when misaligned

Joint points highlighted when detected.

Feedback is continuous while the player is correctly lined up.

3.3 Audio Feedback

Instantaneous audio feedback as soon as alignment is detected or misalignment occurs.

General alerts only:

Misalignment: short alert sound + red line

Correct alignment: positive feedback + green line

Fixed volume; no user controls in MVP.

3.4 User Interaction

Single-player only.

Portrait orientation fixed.

Manual start/stop of practice sessions.

No tutorials, instructions, or extra UI complexity.

Players align themselves to the table; app does not guide positioning.

Practice assumes good indoor lighting and standard billiard table dimensions.

4. Architecture & Technology
4.1 Platform

iOS only (MVP)

Swift / SwiftUI for UI

AVFoundation for live camera feed

4.2 Pose Estimation

MediaPipe Pose or similar library

Detect elbow, wrist, and cue tip

Calculate angle deviation against the fixed center line

4.3 Alignment Logic

Capture coordinates of elbow → wrist → cue tip.

Compare line formed by these points to fixed center line.

Compute angular deviation; threshold ±5° for green/red feedback.

Provide visual/audio feedback in real time.

4.4 UI/UX

Live camera feed with overlay line and joint markers

Fixed center line displayed for reference

Feedback colors: green/red

5. Data Handling

No user data stored

No session logs or history

Temporary in-memory processing of camera feed and keypoints

6. Error Handling & Edge Cases

Detection Failure: no feedback given

Key Point Missing: pause alignment feedback until detected

Low Light or Occlusion: same as above

Device Orientation Locked: ignore rotation

7. Testing Plan
7.1 Functional Tests

Verify pose detection accuracy for elbow → wrist → cue tip

Confirm real-time overlay line color changes correctly based on alignment

Validate audio feedback triggers correctly for aligned and misaligned positions

7.2 Usability Tests

Check ease of use for casual/beginner players

Ensure portrait orientation display works correctly

Confirm front-facing camera view mirrors player accurately

7.3 Performance Tests

Ensure real-time processing at 30+ FPS

Test under good indoor lighting

Validate continuous feedback stability while player holds alignment

7.4 Edge Cases

Detection fails if hand is partially blocked

Misalignment due to moving during feedback

Device accidentally shifted on table edge

8. MVP Exclusions

No head or eye tracking

No multi-player support

No data storage or analytics

No settings for volume, line color, or sensitivity

No tutorials or instructions

No background operation

9. Deliverables for Developer

iOS Swift/SwiftUI project with live camera feed

Pose estimation integration for elbow, wrist, cue tip

Real-time visual overlay system (lines + joint points + center line)

Audio feedback system (misaligned alert + positive alignment cue)

Portrait-only, single-player setup

Testing scripts for alignment, performance, and usability