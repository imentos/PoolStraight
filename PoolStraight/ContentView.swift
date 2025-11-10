import SwiftUI
import AVFoundation

struct ContentView: View, CameraServiceDelegate {
    @State private var isSessionActive = false
    @StateObject private var cameraService = CameraService()
    
    var body: some View {
        ZStack {
            // Live camera feed
            CameraView(session: cameraService.session)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button(action: {
                    isSessionActive.toggle()
                    if isSessionActive {
                        cameraService.startSession()
                    } else {
                        cameraService.stopSession()
                    }
                }) {
                    Text(isSessionActive ? "Stop Practice" : "Start Practice")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isSessionActive ? Color.red : Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            cameraService.delegate = self
            requestCameraPermission()
        }
    }
    
    // MARK: - CameraServiceDelegate
    func didOutput(sampleBuffer: CVPixelBuffer) {
        // This will be used later for pose estimation
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