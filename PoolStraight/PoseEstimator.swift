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
            // Get left elbow and left wrist (which will appear as right side after mirroring for right-handed players)
            let leftElbow = try firstPose.recognizedPoint(.leftElbow)
            let leftWrist = try firstPose.recognizedPoint(.leftWrist)
            
            // Check confidence levels
            if leftElbow.confidence > 0.5 && leftWrist.confidence > 0.5 {
                // Adaptive transform attempting to correct axis swap / rotation issues.
                // Heuristic: If bufferWidth > bufferHeight (common for portrait capture returning landscape buffer), swap axes.
                let shouldSwapAxes = lastBufferWidth > lastBufferHeight

                func transformPoint(_ p: VNRecognizedPoint) -> CGPoint {
                    var x = p.location.x
                    var y = p.location.y

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

                let elbowPoint = transformPoint(leftElbow)
                let wristPoint = transformPoint(leftWrist)
                landmarks = [elbowPoint, wristPoint]

                // Structured debug logging every ~30 frames
                debugCounter += 1
                if debugCounter % 30 == 0 {
                    let rawElbow = leftElbow.location
                    let rawWrist = leftWrist.location
                    print("� Transform Debug → buffer: \(lastBufferWidth)x\(lastBufferHeight) swapAxes=\(shouldSwapAxes)" +
                          "\n    Raw Elbow(x: \(String(format: "%.3f", rawElbow.x)), y: \(String(format: "%.3f", rawElbow.y))) → Transformed(x: \(String(format: "%.3f", elbowPoint.x)), y: \(String(format: "%.3f", elbowPoint.y)))" +
                          "\n    Raw Wrist(x: \(String(format: "%.3f", rawWrist.x)), y: \(String(format: "%.3f", rawWrist.y))) → Transformed(x: \(String(format: "%.3f", wristPoint.x)), y: \(String(format: "%.3f", wristPoint.y)))")
                }
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
