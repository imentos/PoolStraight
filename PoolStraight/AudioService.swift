import AVFoundation
import AudioToolbox
import Foundation

class AudioService: ObservableObject {
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            // Use ambient category to respect silent mode but still play sounds
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func playAlignmentSound() {
        DispatchQueue.main.async {
            // Use a pleasant system sound for alignment success
            AudioServicesPlaySystemSound(1057) // SMS tone - pleasant and positive
            print("🔊 Playing alignment success sound (ID: 1057)")
        }
    }
    
    func playMisalignmentSound() {
        DispatchQueue.main.async {
            // Use a more attention-getting sound for misalignment
            AudioServicesPlaySystemSound(1006) // Camera shutter - neutral alert
            print("🔊 Playing misalignment alert sound (ID: 1006)")
        }
    }
    
    func stopAllSounds() {
        // System sounds stop automatically, no need to manage
    }
}