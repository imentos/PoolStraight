Billiard Straight-Strike Training App – MVP Specification
1. Overview

An iOS app designed for casual or beginner billiard players to practice straight strikes. The app provides real-time visual and audio feedback to help players align their elbow → wrist → cue tip with a fixed center line toward the target pocket.

2. Target User

Casual or beginner billiard players

Right-handed only (MVP)

3. Core Features
3.1 Real-Time Pose Detection

Track shoulder, elbow (optional), wrist, and head position using pose estimation.

Head tilt monitoring ensures proper eye alignment with the strike plane.

Feedback is given only when key arm points are visible; head detection enhances accuracy when available.

Front-facing camera used for a mirror-style view.

Detection starts automatically when the live camera feed opens.

3.2 Visual Feedback

Overlay lines: shoulder → elbow → wrist (primary cue alignment).

Head level indicator: eye-to-eye line shows head tilt status.

Fixed center line overlay on the table for aiming.

Color indicators:

Green line when arm aligned within threshold and head level

Red line when arm misaligned or head significantly tilted

Cyan line for head level indicator when properly positioned

Orange line for head tilt warning

Joint points highlighted when detected.

Feedback is continuous while the player maintains proper alignment.

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

Apple Vision framework with VNDetectHumanBodyPoseRequest

Detect shoulder, elbow (optional), wrist, and head landmarks (eyes, nose)

Calculate angle deviation against the fixed center line

Monitor head tilt for proper eye alignment with strike plane

4.3 Alignment Logic

Capture coordinates of shoulder → elbow → wrist for cue alignment.

Monitor head tilt using eye positions to ensure level head position.

Adaptive detection: uses 2-point (shoulder-wrist) when elbow not visible, 3-point when all detected.

Compare arm line to fixed center line with configurable sensitivity thresholds.

Head tilt threshold: ±6° to ±15° depending on skill level.

Combine arm alignment and head position for overall feedback.

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