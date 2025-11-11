import AVFoundation
import Foundation

class AudioService: ObservableObject {
    private var alignedPlayer: AVAudioPlayer?
    private var misalignedPlayer: AVAudioPlayer?
    
    init() {
        configureAudioSession()
        setupAudioPlayers()
    }
    
    private func configureAudioSession() {
        do {
            // Use ambient category to respect device volume and silent mode
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured to respect device volume")
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
        }
    }
    
    private func setupAudioPlayers() {
        // Create proper WAV audio files that respect volume settings
        setupAlignedSound()
        setupMisalignedSound()
    }
    
    private func setupAlignedSound() {
        if let soundURL = createProperWAVTone(frequency: 800, duration: 0.3, filename: "aligned_tone") {
            do {
                alignedPlayer = try AVAudioPlayer(contentsOf: soundURL)
                alignedPlayer?.prepareToPlay()
                alignedPlayer?.volume = 0.6 // Increased volume (60% instead of 30%)
                print("✅ Aligned sound loaded (volume: 60%)")
            } catch {
                print("⚠️ Failed to load aligned sound: \(error)")
            }
        }
    }
    
    private func setupMisalignedSound() {
        if let soundURL = createProperWAVTone(frequency: 400, duration: 0.2, filename: "misaligned_tone") {
            do {
                misalignedPlayer = try AVAudioPlayer(contentsOf: soundURL)
                misalignedPlayer?.prepareToPlay()
                misalignedPlayer?.volume = 0.5 // Increased volume (50% instead of 20%)
                print("✅ Misaligned sound loaded (volume: 50%)")
            } catch {
                print("⚠️ Failed to load misaligned sound: \(error)")
            }
        }
    }
    
    private func createProperWAVTone(frequency: Float, duration: Float, filename: String) -> URL? {
        let sampleRate: Float = 44100
        let samples = Int(sampleRate * duration)
        
        // Create audio buffer with proper WAV format
        var audioData = Data()
        
        // WAV header (44 bytes)
        let wavHeader = createWAVHeader(sampleRate: Int32(sampleRate), samples: samples)
        audioData.append(wavHeader)
        
        // Generate audio samples
        for i in 0..<samples {
            let time = Float(i) / sampleRate
            // Create a softer tone with fade in/out to reduce harshness
            let fadeLength = Int(sampleRate * 0.05) // 50ms fade
            var envelope: Float = 1.0
            
            if i < fadeLength {
                envelope = Float(i) / Float(fadeLength) // Fade in
            } else if i > samples - fadeLength {
                envelope = Float(samples - i) / Float(fadeLength) // Fade out
            }
            
            let amplitude = sin(2.0 * Float.pi * frequency * time) * envelope * 0.5 // Increased amplitude
            let sample = Int16(amplitude * 16383) // Convert to 16-bit
            
            // Append as little-endian bytes
            audioData.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("\(filename).wav")
        
        do {
            try audioData.write(to: audioURL)
            print("✅ Created WAV file: \(audioURL.lastPathComponent)")
            return audioURL
        } catch {
            print("⚠️ Failed to create WAV file: \(error)")
            return nil
        }
    }
    
    private func createWAVHeader(sampleRate: Int32, samples: Int) -> Data {
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        let fileSize = UInt32(36 + samples * 2) // 36 byte header + data
        header.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // Format chunk
        header.append("fmt ".data(using: .ascii)!)
        let fmtChunkSize = UInt32(16)
        header.append(contentsOf: withUnsafeBytes(of: fmtChunkSize.littleEndian) { Array($0) })
        let audioFormat = UInt16(1) // PCM
        header.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) })
        let numChannels = UInt16(1) // Mono
        header.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        let byteRate = UInt32(sampleRate * 2) // sampleRate * numChannels * bitsPerSample/8
        header.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = UInt16(2) // numChannels * bitsPerSample/8
        header.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        let bitsPerSample = UInt16(16)
        header.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        
        // Data chunk header
        header.append("data".data(using: .ascii)!)
        let dataSize = UInt32(samples * 2)
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        
        return header
    }
    
    // MARK: - Public Methods
    
    func playAlignmentSound() {
        DispatchQueue.main.async { [weak self] in
            self?.alignedPlayer?.stop()
            self?.alignedPlayer?.currentTime = 0
            self?.alignedPlayer?.play()
            print("🔊 Playing alignment success sound (respects volume)")
        }
    }
    
    func playMisalignmentSound() {
        DispatchQueue.main.async { [weak self] in
            self?.misalignedPlayer?.stop()
            self?.misalignedPlayer?.currentTime = 0
            self?.misalignedPlayer?.play()
            print("🔊 Playing misalignment alert sound (respects volume)")
        }
    }
    
    func stopAllSounds() {
        alignedPlayer?.stop()
        misalignedPlayer?.stop()
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        alignedPlayer?.volume = clampedVolume * 0.6 // Scale with increased base volume
        misalignedPlayer?.volume = clampedVolume * 0.5
        print("🔊 Audio volume set to: \(Int(clampedVolume * 100))%")
    }
}