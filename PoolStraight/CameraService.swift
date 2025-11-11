import AVFoundation
import SwiftUI

protocol CameraServiceDelegate {
    func didOutput(sampleBuffer: CVPixelBuffer)
}

class CameraService: NSObject, ObservableObject {
    var delegate: CameraServiceDelegate?
    
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Configure session preset
        session.sessionPreset = .high
        
        // Setup video input (front-facing camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("Failed to setup video input")
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoInput)
        
        // Setup video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        guard session.canAddOutput(videoOutput) else {
            print("Failed to setup video output")
            session.commitConfiguration()
            return
        }
        
        session.addOutput(videoOutput)
        
        session.commitConfiguration()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Set video rotation for iOS 17+ compatibility
        if #available(iOS 17.0, *) {
            connection.videoRotationAngle = 0 // Portrait orientation
        } else {
            connection.videoOrientation = .portrait
        }
        
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didOutput(sampleBuffer: pixelBuffer)
        }
    }
}
