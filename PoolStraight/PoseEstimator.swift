import Foundation
import CoreGraphics
import CoreVideo
import Vision

protocol PoseEstimatorDelegate {
    func didDetect(landmarks: [CGPoint])
}

class PoseEstimator: ObservableObject {
    var delegate: PoseEstimatorDelegate?
    
    // Vision framework components
    private var poseRequest: VNDetectHumanBodyPoseRequest?
    private let sequenceHandler = VNSequenceRequestHandler()
    
    // Throttling for performance
    private var lastProcessTime: TimeInterval = 0
    private let processingInterval: TimeInterval = 1.0 / 15.0 // 15 FPS for pose detection
    private var isDetecting = false

    // Track last buffer dimensions to infer orientation / rotation
    private var lastBufferWidth: Int = 0
    private var lastBufferHeight: Int = 0
    private var debugCounter: Int = 0
    
    init() {
        setupVisionRequest()
    }
    
    private func setupVisionRequest() {
        poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                print("⚠️ Pose detection error: \(error.localizedDescription)")
                return
            }
            
            self?.processPoseObservations(request.results)
        }
        
        // Configure the request for better performance
        poseRequest?.revision = VNDetectHumanBodyPoseRequestRevision1
    }
    
    func processFrame(_ buffer: CVPixelBuffer) {
        // Throttle processing for performance
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastProcessTime >= processingInterval else { return }
        lastProcessTime = currentTime
        
        // Only process if detection is active
        guard isDetecting, let request = poseRequest else { return }

    // Capture current buffer dimensions (used for orientation heuristics)
    lastBufferWidth = CVPixelBufferGetWidth(buffer)
    lastBufferHeight = CVPixelBufferGetHeight(buffer)
        
        // Perform pose detection on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.sequenceHandler.perform([request], on: buffer)
            } catch {
                print("⚠️ Failed to perform pose detection: \(error)")
            }
        }
    }
    
    private func processPoseObservations(_ observations: [VNObservation]?) {
        guard let poseObservations = observations as? [VNHumanBodyPoseObservation],
              let firstPose = poseObservations.first else {
            // No pose detected
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didDetect(landmarks: [])
            }
            return
        }
        
        // Extract elbow and wrist points
        var landmarks: [CGPoint] = []
        
        do {
            // Get left shoulder, elbow and wrist (which will appear as right side after mirroring for right-handed players)
            let leftShoulder = try firstPose.recognizedPoint(.leftShoulder)
            let leftElbow = try firstPose.recognizedPoint(.leftElbow)
            let leftWrist = try firstPose.recognizedPoint(.leftWrist)
            
            // Get head landmarks for tilt detection AND as shoulder fallback when leaning
            let leftEye = try firstPose.recognizedPoint(.leftEye)
            let rightEye = try firstPose.recognizedPoint(.rightEye)
            let nose = try firstPose.recognizedPoint(.nose)
            
            // Enhanced detection for billiard stance: use eyes as shoulder reference when leaning
            var shoulderConfidence: Float
            var useEyeBasedShoulder = false
            
            // When players lean down, eyes might be more reliable than shoulder/neck
            if leftShoulder.confidence > 0.5 {
                // Normal upright pose - use shoulder
                shoulderConfidence = leftShoulder.confidence
                useEyeBasedShoulder = false
            } else if leftEye.confidence > 0.4 && rightEye.confidence > 0.4 {
                // Leaning pose - use eye position as upper body reference
                shoulderConfidence = (leftEye.confidence + rightEye.confidence) / 2
                useEyeBasedShoulder = true
                
                print("🎱 Billiard lean detected - using eye-based shoulder estimation (conf: \(String(format: "%.3f", shoulderConfidence)))")
            } else {
                // Fallback to original shoulder even with low confidence
                shoulderConfidence = leftShoulder.confidence
                useEyeBasedShoulder = false
            }
            
            // Check confidence levels - more lenient for billiard stance
            if shoulderConfidence > 0.3 && leftWrist.confidence > 0.3 {
                // Adaptive transform attempting to correct axis swap / rotation issues.
                // Heuristic: If bufferWidth > bufferHeight (common for portrait capture returning landscape buffer), swap axes.
                let shouldSwapAxes = lastBufferWidth > lastBufferHeight

                func transformPoint(_ p: VNRecognizedPoint, isShoulderPoint: Bool = false) -> CGPoint {
                    var x: CGFloat
                    var y: CGFloat
                    
                    if isShoulderPoint && useEyeBasedShoulder && leftEye.confidence > 0.4 && rightEye.confidence > 0.4 {
                        // Use eye-based estimation for shoulder position
                        let averageEyeX = (leftEye.location.x + rightEye.location.x) / 2
                        let averageEyeY = (leftEye.location.y + rightEye.location.y) / 2
                        let estimatedShoulderY = averageEyeY - 0.12 // 12% below eyes
                        
                        x = averageEyeX
                        y = estimatedShoulderY
                    } else {
                        x = p.location.x
                        y = p.location.y
                    }

                    // If axes are swapped due to buffer orientation, swap first.
                    if shouldSwapAxes {
                        let tmp = x
                        x = y
                        y = tmp
                    }

                    // Vision origin is bottom-left; convert to top-left by flipping Y.
                    y = 1.0 - y

                    // Mirror horizontally for front camera (so movement feels natural like a mirror).
                    x = 1.0 - x

                    return CGPoint(x: x, y: y)
                }

                // Use eye estimation for shoulder if we're in lean mode
                let shoulderPoint = transformPoint(leftShoulder, isShoulderPoint: true)
                let wristPoint = transformPoint(leftWrist)
                
                var detectedPoints: [CGPoint] = [shoulderPoint] // Always start with shoulder (or eye-estimated shoulder)
                
                // Add elbow if detected with good confidence (more lenient for leaning pose)
                if leftElbow.confidence > 0.3 {
                    let elbowPoint = transformPoint(leftElbow)
                    detectedPoints.append(elbowPoint)
                }
                
                // Always add wrist as the next point
                detectedPoints.append(wristPoint)
                
                // Add head landmarks if available for tilt detection
                if leftEye.confidence > 0.3 && rightEye.confidence > 0.3 {
                    let leftEyePoint = transformPoint(leftEye)
                    let rightEyePoint = transformPoint(rightEye)
                    detectedPoints.append(leftEyePoint)
                    detectedPoints.append(rightEyePoint)
                    
                    // Add nose if available for additional head reference
                    if nose.confidence > 0.3 {
                        let nosePoint = transformPoint(nose)
                        detectedPoints.append(nosePoint)
                    }
                }
                
                landmarks = detectedPoints

                // Enhanced debug logging for billiard stance
                debugCounter += 1
                if debugCounter % 30 == 0 {
                    let rawShoulder = leftShoulder.location
                    let rawWrist = leftWrist.location
                    print("🎯 Enhanced Billiard Debug → buffer: \(lastBufferWidth)x\(lastBufferHeight) swapAxes=\(shouldSwapAxes)")
                    
                    if useEyeBasedShoulder {
                        print("    Using EYE-BASED shoulder estimation for leaning pose")
                        print("    Left Eye conf: \(String(format: "%.3f", leftEye.confidence)), Right Eye conf: \(String(format: "%.3f", rightEye.confidence))")
                        print("    Shoulder conf: \(String(format: "%.3f", leftShoulder.confidence)) (too low, using eyes)")
                    } else {
                        print("    Using standard shoulder detection")
                        print("    Shoulder conf: \(String(format: "%.3f", shoulderConfidence))")
                    }
                    
                    print("    Raw Shoulder(x: \(String(format: "%.3f", rawShoulder.x)), y: \(String(format: "%.3f", rawShoulder.y))) → Transformed(x: \(String(format: "%.3f", shoulderPoint.x)), y: \(String(format: "%.3f", shoulderPoint.y)))")
                    print("    Raw Wrist(x: \(String(format: "%.3f", rawWrist.x)), y: \(String(format: "%.3f", rawWrist.y))) → Transformed(x: \(String(format: "%.3f", wristPoint.x)), y: \(String(format: "%.3f", wristPoint.y)))")
                    
                    var detectionMode = useEyeBasedShoulder ? "Eye-Based Shoulder+Wrist" : "Standard Shoulder+Wrist"
                    if leftElbow.confidence > 0.3 {
                        detectionMode = useEyeBasedShoulder ? "Eye-Based 3-point (E-S+E+W)" : "Standard 3-point (S+E+W)"
                        let rawElbow = leftElbow.location
                        let elbowPoint = transformPoint(leftElbow)
                        print("    Raw Elbow(x: \(String(format: "%.3f", rawElbow.x)), y: \(String(format: "%.3f", rawElbow.y))) → Transformed(x: \(String(format: "%.3f", elbowPoint.x)), y: \(String(format: "%.3f", elbowPoint.y)))")
                    }
                    
                    if leftEye.confidence > 0.3 && rightEye.confidence > 0.3 {
                        detectionMode += "+Head"
                        let leftEyePoint = transformPoint(leftEye)
                        let rightEyePoint = transformPoint(rightEye)
                        
                        // Calculate head tilt angle for debug
                        let eyeDeltaX = rightEyePoint.x - leftEyePoint.x
                        let eyeDeltaY = rightEyePoint.y - leftEyePoint.y
                        let headTiltRadians = atan2(eyeDeltaY, eyeDeltaX)
                        let headTiltDegrees = headTiltRadians * 180.0 / Double.pi
                        
                        print("    Head tilt: \(String(format: "%.1f", headTiltDegrees))° (0° = level head)")
                    }
                    
                    print("    Detection mode: \(detectionMode)")
                }
            } else {
                // Log why detection failed with billiard context
                print("⚠️ Billiard pose detection failed:")
                print("   Shoulder conf: \(String(format: "%.3f", leftShoulder.confidence))")
                print("   Eye-based conf: \(leftEye.confidence > 0.4 && rightEye.confidence > 0.4 ? String(format: "%.3f", (leftEye.confidence + rightEye.confidence) / 2) : "N/A")")
                print("   Wrist conf: \(String(format: "%.3f", leftWrist.confidence))")
                print("   Try adjusting lighting or lean angle slightly")
            }
            
        } catch {
            print("⚠️ Error extracting pose points: \(error)")
        }
        
        // Call delegate on main thread
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didDetect(landmarks: landmarks)
        }
    }
    
    func startDetection() {
        isDetecting = true
        print("🔍 Apple Vision pose detection started")
    }
    
    func stopDetection() {
        isDetecting = false
        print("🔍 Apple Vision pose detection stopped")
    }
}
