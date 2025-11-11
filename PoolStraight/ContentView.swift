import SwiftUI
import AVFoundation

struct ContentView: View, CameraServiceDelegate, PoseEstimatorDelegate {
    @State private var isSessionActive = true // Always active; auto-start
    @StateObject private var cameraService = CameraService()
    @StateObject private var poseEstimator = PoseEstimator()
    @StateObject private var audioService = AudioService()
    @State private var detectedPoints: [CGPoint] = []
    @State private var alignmentStatus: AlignmentStatus = .notDetected
    @State private var previousAlignmentStatus: AlignmentStatus = .notDetected
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Live camera feed
                CameraView(session: cameraService.session)
                    .ignoresSafeArea()
                
                // Overlay for pose visualization
                OverlayView(
                    detectedPoints: detectedPoints,
                    alignmentStatus: alignmentStatus,
                    geometryProxy: geometry
                )
                .ignoresSafeArea()
                
                // Removed start/stop button and not detected banner per user request
            }
        }
        .onAppear {
            cameraService.delegate = self
            poseEstimator.delegate = self
            requestCameraPermission()
            // Auto-start session
            cameraService.startSession()
            poseEstimator.startDetection()
            previousAlignmentStatus = .notDetected
        }
    }
    
    // MARK: - CameraServiceDelegate
    func didOutput(sampleBuffer: CVPixelBuffer) {
        // Process frame with pose estimator (every 30th frame to avoid spam)
        if Int.random(in: 1...30) == 1 {
            print("📷 Processing camera frame for pose detection")
        }
        poseEstimator.processFrame(sampleBuffer)
    }
    
    // MARK: - PoseEstimatorDelegate
    func didDetect(landmarks: [CGPoint]) {
        print("📱 ContentView received landmarks: \(landmarks.count) points")
        detectedPoints = landmarks
        
        // Calculate alignment status using AlignmentLogic
        let newAlignmentStatus = AlignmentLogic.calculateAlignment(points: landmarks, centerLineX: 0.5)
        print("📐 Alignment status: \(newAlignmentStatus)")
        
        // Check if alignment status changed and play appropriate sound
        if newAlignmentStatus != previousAlignmentStatus && isSessionActive {
            handleAlignmentStatusChange(from: previousAlignmentStatus, to: newAlignmentStatus)
        }
        
        // Update states
        previousAlignmentStatus = alignmentStatus
        alignmentStatus = newAlignmentStatus
    }
    
    private func handleAlignmentStatusChange(from previous: AlignmentStatus, to current: AlignmentStatus) {
        switch current {
        case .aligned:
            if previous == .misaligned {
                audioService.playAlignmentSound()
                print("🎵 Alignment achieved! Playing success sound")
            }
        case .misaligned:
            if previous == .aligned || previous == .notDetected {
                audioService.playMisalignmentSound()
                print("🎵 Misalignment detected! Playing alert sound")
            }
        case .notDetected:
            // No sound for detection loss
            break
        }
    }
    
    // MARK: - Camera Permission
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                print("Camera permission denied")
            }
        }
    }
}

#Preview {
    ContentView()
}