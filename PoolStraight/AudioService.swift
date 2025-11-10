import AVFoundation
import Foundation

class AudioService: ObservableObject {
    private var alignedPlayer: AVAudioPlayer?
    private var misalignedPlayer: AVAudioPlayer?
    
    init() {
        setupAudioPlayers()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
        }
    }
    
    private func setupAudioPlayers() {
        // Create placeholder sounds programmatically if files don't exist
        setupAlignedSound()
        setupMisalignedSound()
    }
    
    private func setupAlignedSound() {
        // For now, we'll create a simple tone programmatically
        // In a real app, you'd load from bundle: Bundle.main.url(forResource: "aligned", withExtension: "wav")
        if let soundURL = createAlignedTone() {
            do {
                alignedPlayer = try AVAudioPlayer(contentsOf: soundURL)
                alignedPlayer?.prepareToPlay()
                alignedPlayer?.volume = 0.7
                print("✅ Aligned sound loaded successfully")
            } catch {
                print("⚠️ Failed to load aligned sound: \(error)")
            }
        }
    }
    
    private func setupMisalignedSound() {
        // For now, we'll create a simple tone programmatically
        if let soundURL = createMisalignedTone() {
            do {
                misalignedPlayer = try AVAudioPlayer(contentsOf: soundURL)
                misalignedPlayer?.prepareToPlay()
                misalignedPlayer?.volume = 0.7
                print("✅ Misaligned sound loaded successfully")
            } catch {
                print("⚠️ Failed to load misaligned sound: \(error)")
            }
        }
    }
    
    // Create a simple success tone (higher pitch, pleasant)
    private func createAlignedTone() -> URL? {
        return createTone(frequency: 800, duration: 0.3, filename: "aligned_tone")
    }
    
    // Create a simple alert tone (lower pitch, attention-getting)
    private func createMisalignedTone() -> URL? {
        return createTone(frequency: 400, duration: 0.2, filename: "misaligned_tone")
    }
    
    private func createTone(frequency: Float, duration: Float, filename: String) -> URL? {
        let sampleRate: Float = 44100
        let samples = Int(sampleRate * duration)
        
        var audioData = [Int16]()
        
        for i in 0..<samples {
            let time = Float(i) / sampleRate
            let amplitude: Int16 = Int16(sin(2.0 * Float.pi * frequency * time) * 16383)
            audioData.append(amplitude)
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("\(filename).wav")
        
        // Create a simple WAV file
        do {
            let data = Data(bytes: audioData, count: audioData.count * MemoryLayout<Int16>.size)
            try data.write(to: audioURL)
            return audioURL
        } catch {
            print("⚠️ Failed to create tone file: \(error)")
            return nil
        }
    }
    
    // MARK: - Public Methods
    
    func playAlignmentSound() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.alignedPlayer?.stop()
            self?.alignedPlayer?.currentTime = 0
            self?.alignedPlayer?.play()
            
            DispatchQueue.main.async {
                print("🔊 Playing alignment success sound")
            }
        }
    }
    
    func playMisalignmentSound() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.misalignedPlayer?.stop()
            self?.misalignedPlayer?.currentTime = 0
            self?.misalignedPlayer?.play()
            
            DispatchQueue.main.async {
                print("🔊 Playing misalignment alert sound")
            }
        }
    }
    
    func stopAllSounds() {
        alignedPlayer?.stop()
        misalignedPlayer?.stop()
    }
}