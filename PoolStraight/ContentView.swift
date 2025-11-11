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
    @State private var currentSensitivity: AlignmentLogic.SensitivityLevel = .beginner // Track UI state
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Live camera feed
                CameraView(session: cameraService.session)
                    .ignoresSafeArea()
                
                // TODO: Add sensitivity controls to settings screen later
                /*
                // Sensitivity adjustment controls (for testing/fine-tuning)
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack {
                            Text("Sensitivity")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            VStack(spacing: 4) {
                                Button("Easy") {
                                    AlignmentLogic.setSensitivity(.beginner)
                                    currentSensitivity = .beginner
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(currentSensitivity == .beginner ? Color.green : Color.gray.opacity(0.7))
                                .cornerRadius(6)
                                
                                Button("Medium") {
                                    AlignmentLogic.setSensitivity(.intermediate)
                                    currentSensitivity = .intermediate
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(currentSensitivity == .intermediate ? Color.green : Color.gray.opacity(0.7))
                                .cornerRadius(6)
                                
                                Button("Hard") {
                                    AlignmentLogic.setSensitivity(.advanced)
                                    currentSensitivity = .advanced
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(currentSensitivity == .advanced ? Color.green : Color.gray.opacity(0.7))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                }
                */
                
                // Overlay for pose visualization (placed AFTER buttons so it doesn't block them)
                OverlayView(
                    detectedPoints: detectedPoints,
                    alignmentStatus: alignmentStatus,
                    geometryProxy: geometry
                )
                .ignoresSafeArea()
                .allowsHitTesting(false) // This should prevent the overlay from intercepting touches
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
        print("🔄 Alignment change: \(previous) → \(current)")
        
        switch current {
        case .aligned:
            if previous == .misaligned || previous == .notDetected {
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
            print("🔇 No pose detected - no sound")
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