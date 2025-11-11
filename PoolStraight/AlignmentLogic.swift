import Foundation
import CoreGraphics

struct AlignmentLogic {
    
    // MARK: - Configurable Sensitivity Parameters
    
    /// Alignment sensitivity levels for different skill levels
    enum SensitivityLevel {
        case beginner    // More forgiving - good for learning
        case intermediate // Moderate precision
        case advanced    // Strict precision for competitive play
        
        var angleThreshold: Double {
            switch self {
            case .beginner: return 12.0      // ±12 degrees
            case .intermediate: return 8.0   // ±8 degrees  
            case .advanced: return 5.0       // ±5 degrees
            }
        }
        
        var lateralThreshold: CGFloat {
            switch self {
            case .beginner: return 0.12      // ±12% of screen width
            case .intermediate: return 0.08  // ±8% of screen width
            case .advanced: return 0.05      // ±5% of screen width
            }
        }
        
        var wristWeight: CGFloat {
            switch self {
            case .beginner: return 0.6       // Less wrist emphasis for beginners
            case .intermediate: return 0.7   // Balanced
            case .advanced: return 0.8       // High wrist emphasis for precision
            }
        }
    }
    
    // Current sensitivity level - can be adjusted during testing
    static var currentSensitivity: SensitivityLevel = .beginner
    
    /// Calculates alignment status based on elbow and wrist positions relative to center line
    /// - Parameters:
    ///   - points: Array containing elbow (index 0) and wrist (index 1) coordinates (normalized 0-1)
    ///   - centerLineX: X-coordinate of the center line (normalized, typically 0.5)
    ///   - sensitivity: Optional sensitivity override
    /// - Returns: AlignmentStatus indicating if the arm alignment is correct
    static func calculateAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5, sensitivity: SensitivityLevel? = nil) -> AlignmentStatus {
        
        // Check if we have at least two points (elbow and wrist)
        guard points.count >= 2 else {
            return .notDetected
        }
        
        let elbow = points[0]
        let wrist = points[1]
        
        // Ensure points are reasonable (within bounds)
        guard isValidPoint(elbow) && isValidPoint(wrist) else {
            return .notDetected
        }
        
        // Use provided sensitivity or default
        let activeSensitivity = sensitivity ?? currentSensitivity
        
        // Use combined approach: both angle and lateral deviation
        let angleAlignment = calculateAngleAlignment(elbow: elbow, wrist: wrist, sensitivity: activeSensitivity)
        let lateralAlignment = calculateLateralAlignment(elbow: elbow, wrist: wrist, centerLineX: centerLineX, sensitivity: activeSensitivity)
        
        // For billiard training, prioritize angle over lateral position
        // This matches real-world billiard technique where arm angle is more critical
        switch (angleAlignment, lateralAlignment) {
        case (.aligned, .aligned):
            return .aligned
        case (.aligned, .misaligned):
            // Good angle but off-center - still provide some positive feedback for beginners
            return activeSensitivity == .beginner ? .aligned : .misaligned
        case (.misaligned, _):
            return .misaligned
        case (.notDetected, _), (_, .notDetected):
            return .notDetected
        }
    }
    
    private static func calculateAngleAlignment(elbow: CGPoint, wrist: CGPoint, sensitivity: SensitivityLevel) -> AlignmentStatus {
        // Calculate angle of the line formed by elbow and wrist
        let deltaY = wrist.y - elbow.y
        let deltaX = wrist.x - elbow.x
        
        // Ensure wrist is below elbow (proper positioning for billiard stance)
        guard deltaY > 0.02 else { // Small threshold to avoid noise
            return .misaligned
        }
        
        // Calculate angle in radians (atan2 returns angle from -π to π)
        let armAngleRadians = atan2(deltaY, deltaX)
        
        // Vertical center line angle (pointing downward) - adjusted for billiard stance
        let verticalAngleRadians = Double.pi / 2  // 90 degrees (pointing down)
        
        // Calculate absolute difference between arm angle and vertical
        var angleDifference = abs(armAngleRadians - verticalAngleRadians)
        
        // Handle angle wrapping (ensure we get the smaller angle)
        if angleDifference > Double.pi {
            angleDifference = 2 * Double.pi - angleDifference
        }
        
        // Convert to degrees for easier threshold checking
        let angleDifferenceInDegrees = angleDifference * 180.0 / Double.pi
        
        // Use sensitivity-based threshold
        let alignmentThreshold = sensitivity.angleThreshold
        
        // Debug logging for fine-tuning
        if angleDifferenceInDegrees > alignmentThreshold {
            print("🎯 Angle deviation: \(String(format: "%.1f", angleDifferenceInDegrees))° (threshold: \(alignmentThreshold)°)")
        }
        
        return angleDifferenceInDegrees <= alignmentThreshold ? .aligned : .misaligned
    }
    
    private static func calculateLateralAlignment(elbow: CGPoint, wrist: CGPoint, centerLineX: CGFloat, sensitivity: SensitivityLevel) -> AlignmentStatus {
        // For billiard stance, the wrist position is most important for cue alignment
        let elbowWeight = 1.0 - sensitivity.wristWeight
        let wristWeight = sensitivity.wristWeight
        
        let weightedX = (elbow.x * elbowWeight) + (wrist.x * wristWeight)
        
        // Calculate lateral deviation from center line
        let lateralDeviation = abs(weightedX - centerLineX)
        
        // Use sensitivity-based threshold
        let lateralThreshold = sensitivity.lateralThreshold
        
        // Debug logging for fine-tuning
        if lateralDeviation > lateralThreshold {
            print("🎯 Lateral deviation: \(String(format: "%.3f", lateralDeviation)) (threshold: \(lateralThreshold))")
        }
        
        return lateralDeviation <= lateralThreshold ? .aligned : .misaligned
    }
    
    private static func isValidPoint(_ point: CGPoint) -> Bool {
        return point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1
    }
    
    // MARK: - Sensitivity Adjustment Methods
    
    /// Adjust sensitivity based on user performance or preference
    static func setSensitivity(_ level: SensitivityLevel) {
        currentSensitivity = level
        print("🎯 Alignment sensitivity set to: \(level)")
    }
    
    /// Get current sensitivity parameters for debugging
    static func getCurrentSensitivityInfo() -> (angle: Double, lateral: CGFloat, wristWeight: CGFloat) {
        return (
            angle: currentSensitivity.angleThreshold,
            lateral: currentSensitivity.lateralThreshold,
            wristWeight: currentSensitivity.wristWeight
        )
    }
    
    /// Test method to evaluate alignment with all sensitivity levels
    static func testAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5) -> [SensitivityLevel: AlignmentStatus] {
        var results: [SensitivityLevel: AlignmentStatus] = [:]
        
        for level in [SensitivityLevel.beginner, .intermediate, .advanced] {
            results[level] = calculateAlignment(points: points, centerLineX: centerLineX, sensitivity: level)
        }
        
        return results
    }
    
    /// Legacy method for simpler lateral-only alignment (kept for compatibility)
    static func calculateLateralAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5) -> AlignmentStatus {
        
        guard points.count >= 2 else {
            return .notDetected
        }
        
        let elbow = points[0]
        let wrist = points[1]
        
        // Calculate average X position of elbow and wrist
        let averageX = (elbow.x + wrist.x) / 2
        
        // Calculate lateral deviation from center line
        let lateralDeviation = abs(averageX - centerLineX)
        
        // Threshold for lateral alignment (±0.05 = 5% of screen width)
        let lateralThreshold: CGFloat = 0.05
        
        if lateralDeviation <= lateralThreshold {
            return .aligned
        } else {
            return .misaligned
        }
    }
}