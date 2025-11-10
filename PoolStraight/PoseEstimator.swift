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
            // Get right elbow and right wrist (for right-handed players)
            let rightElbow = try firstPose.recognizedPoint(.rightElbow)
            let rightWrist = try firstPose.recognizedPoint(.rightWrist)
            
            // Check confidence levels
            if rightElbow.confidence > 0.5 && rightWrist.confidence > 0.5 {
                // Convert from Vision coordinates (bottom-left origin) to normalized coordinates (top-left origin)
                let elbowPoint = CGPoint(x: rightElbow.location.x, y: 1.0 - rightElbow.location.y)
                let wristPoint = CGPoint(x: rightWrist.location.x, y: 1.0 - rightWrist.location.y)
                
                landmarks = [elbowPoint, wristPoint]
                
                // Log occasionally for debugging
                if Int.random(in: 1...45) == 1 {
                    print("🔍 Vision pose detected: Elbow(\(String(format: "%.2f", elbowPoint.x)), \(String(format: "%.2f", elbowPoint.y))) Wrist(\(String(format: "%.2f", wristPoint.x)), \(String(format: "%.2f", wristPoint.y)))")
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