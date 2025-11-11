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
        
        var headTiltThreshold: Double {
            switch self {
            case .beginner: return 8.0       // ±8 degrees head tilt allowed (more strict)
            case .intermediate: return 5.0   // ±5 degrees head tilt allowed 
            case .advanced: return 3.0       // ±3 degrees head tilt allowed (very strict)
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
    
    /// Calculates alignment status based on shoulder, elbow (optional), wrist, and head tilt
    /// - Parameters:
    ///   - points: Array containing arm points [shoulder, (elbow), wrist] + optional head points [leftEye, rightEye, (nose)]
    ///   - centerLineX: X-coordinate of the center line (normalized, typically 0.5)
    ///   - sensitivity: Optional sensitivity override
    /// - Returns: AlignmentStatus indicating if the overall alignment is correct
    static func calculateAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5, sensitivity: SensitivityLevel? = nil) -> AlignmentStatus {
        
        // Check if we have at least two points (shoulder and wrist minimum)
        guard points.count >= 2 else {
            return .notDetected
        }
        
        // Parse points into arm and head components
        var armPoints: [CGPoint] = []
        var headPoints: [CGPoint] = []
        
        // Identify arm vs head points based on typical detection patterns
        // First point is always shoulder, then elbow (optional), then wrist
        armPoints.append(points[0]) // shoulder
        
        if points.count == 2 {
            // [shoulder, wrist]
            armPoints.append(points[1])
        } else if points.count == 3 {
            // Could be [shoulder, elbow, wrist] or [shoulder, wrist, leftEye]
            let secondY = points[1].y
            let thirdY = points[2].y
            
            // If second point is above third, it's likely elbow-wrist
            if secondY < thirdY {
                armPoints.append(points[1]) // elbow
                armPoints.append(points[2]) // wrist
            } else {
                armPoints.append(points[1]) // wrist
                headPoints.append(points[2]) // leftEye
            }
        } else {
            // Multiple points - separate arm from head
            // Assume shoulder + elbow/wrist, then head landmarks
            armPoints.append(points[1]) // elbow or wrist
            
            if points.count >= 3 && points[1].y < points[2].y {
                armPoints.append(points[2]) // wrist
                // Rest are head points
                for i in 3..<points.count {
                    headPoints.append(points[i])
                }
            } else {
                // Second point is wrist, rest are head points
                for i in 2..<points.count {
                    headPoints.append(points[i])
                }
            }
        }
        
        // Validate we have minimum arm points
        guard armPoints.count >= 2 else { return .notDetected }
        
        let shoulder = armPoints[0]
        let wrist = armPoints.last!
        
        // Ensure points are reasonable (within bounds)
        guard isValidPoint(shoulder) && isValidPoint(wrist) else {
            return .notDetected
        }
        
        // Use provided sensitivity or default
        let activeSensitivity = sensitivity ?? currentSensitivity
        
        // Calculate arm alignment
        let armAlignment: AlignmentStatus
        if armPoints.count >= 3 {
            let elbow = armPoints[1]
            if isValidPoint(elbow) {
                armAlignment = calculateThreePointAlignment(shoulder: shoulder, elbow: elbow, wrist: wrist, centerLineX: centerLineX, sensitivity: activeSensitivity)
            } else {
                armAlignment = calculateTwoPointAlignment(shoulder: shoulder, wrist: wrist, centerLineX: centerLineX, sensitivity: activeSensitivity)
            }
        } else {
            armAlignment = calculateTwoPointAlignment(shoulder: shoulder, wrist: wrist, centerLineX: centerLineX, sensitivity: activeSensitivity)
        }
        
        // Calculate head alignment if head points are available
        if headPoints.count >= 2 {
            let headAlignment = calculateHeadAlignment(headPoints: headPoints, sensitivity: activeSensitivity)
            
            // Combine arm and head alignment
            switch (armAlignment, headAlignment) {
            case (.aligned, .aligned):
                return .aligned
            case (.aligned, .misaligned):
                // Good arm but head tilted - provide feedback for improvement
                return activeSensitivity == .beginner ? .aligned : .misaligned
            case (.misaligned, _):
                return .misaligned // Arm alignment takes priority
            case (.notDetected, _), (_, .notDetected):
                return .notDetected
            }
        } else {
            // No head detection available, use arm alignment only
            return armAlignment
        }
    }
    
    // MARK: - Helper Methods for Different Point Configurations
    
    private static func calculateTwoPointAlignment(shoulder: CGPoint, wrist: CGPoint, centerLineX: CGFloat, sensitivity: SensitivityLevel) -> AlignmentStatus {
        // Use combined approach: both angle and lateral deviation
        let angleAlignment = calculateAngleAlignment(elbow: shoulder, wrist: wrist, sensitivity: sensitivity)
        let lateralAlignment = calculateLateralAlignment(elbow: shoulder, wrist: wrist, centerLineX: centerLineX, sensitivity: sensitivity)
        
        // For billiard training, prioritize angle over lateral position
        switch (angleAlignment, lateralAlignment) {
        case (.aligned, .aligned):
            return .aligned
        case (.aligned, .misaligned):
            // Good angle but off-center - still provide some positive feedback for beginners
            return sensitivity == .beginner ? .aligned : .misaligned
        case (.misaligned, _):
            return .misaligned
        case (.notDetected, _), (_, .notDetected):
            return .notDetected
        }
    }
    
    private static func calculateThreePointAlignment(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint, centerLineX: CGFloat, sensitivity: SensitivityLevel) -> AlignmentStatus {
        // Check that the three points form a reasonable arm configuration
        // Ensure shoulder is above elbow, and elbow is above wrist (proper billiard stance)
        guard shoulder.y < elbow.y && elbow.y < wrist.y else {
            // Invalid arm configuration, fall back to shoulder-wrist
            return calculateTwoPointAlignment(shoulder: shoulder, wrist: wrist, centerLineX: centerLineX, sensitivity: sensitivity)
        }
        
        // Calculate alignment using the full arm configuration
        // Use elbow-wrist for primary angle calculation (most important for cue alignment)
        let primaryAngleAlignment = calculateAngleAlignment(elbow: elbow, wrist: wrist, sensitivity: sensitivity)
        
        // Use shoulder-elbow for secondary validation (arm posture)
        let shoulderElbowAngleAlignment = calculateAngleAlignment(elbow: shoulder, wrist: elbow, sensitivity: sensitivity)
        
        // Calculate lateral alignment using all three points with proper weighting
        let weightedX = (shoulder.x * 0.2) + (elbow.x * 0.3) + (wrist.x * 0.5) // Wrist most important
        let lateralDeviation = abs(weightedX - centerLineX)
        let lateralThreshold = sensitivity.lateralThreshold
        let lateralAlignment: AlignmentStatus = lateralDeviation <= lateralThreshold ? .aligned : .misaligned
        
        // Debug logging for fine-tuning
        if primaryAngleAlignment == .misaligned || lateralAlignment == .misaligned {
            print("🎯 3-point alignment: primary=\(primaryAngleAlignment), shoulderElbow=\(shoulderElbowAngleAlignment), lateral=\(lateralAlignment)")
        }
        
        // Combine results - prioritize the elbow-wrist alignment as it's most critical for cue positioning
        switch (primaryAngleAlignment, lateralAlignment) {
        case (.aligned, .aligned):
            return .aligned
        case (.aligned, .misaligned):
            // Good cue angle but off-center
            return sensitivity == .beginner ? .aligned : .misaligned
        case (.misaligned, _):
            return .misaligned
        case (.notDetected, _), (_, .notDetected):
            return .notDetected
        }
    }
    
    private static func calculateHeadAlignment(headPoints: [CGPoint], sensitivity: SensitivityLevel) -> AlignmentStatus {
        guard headPoints.count >= 2 else { return .notDetected }
        
        // Use first two points as left and right eyes
        let leftEye = headPoints[0]
        let rightEye = headPoints[1]
        
        // Validate head points
        guard isValidPoint(leftEye) && isValidPoint(rightEye) else {
            return .notDetected
        }
        
        // Calculate head tilt angle
        let eyeDeltaX = rightEye.x - leftEye.x
        let eyeDeltaY = rightEye.y - leftEye.y
        
        // Calculate angle in degrees (0° = level head)
        let headTiltRadians = atan2(eyeDeltaY, eyeDeltaX)
        var headTiltDegrees = headTiltRadians * 180.0 / Double.pi
        
        // Normalize angle to [-90, 90] range for easier threshold checking
        if headTiltDegrees > 90 {
            headTiltDegrees = headTiltDegrees - 180
        } else if headTiltDegrees < -90 {
            headTiltDegrees = headTiltDegrees + 180
        }
        
        let absoluteTilt = abs(headTiltDegrees)
        let tiltThreshold = sensitivity.headTiltThreshold
        
        // Debug logging for fine-tuning
        if absoluteTilt > tiltThreshold {
            print("👁️ Head tilt: \(String(format: "%.1f", headTiltDegrees))° (threshold: ±\(tiltThreshold)°)")
        }
        
        return absoluteTilt <= tiltThreshold ? .aligned : .misaligned
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
    /// Note: This method expects the old 2-point format (elbow, wrist)
    static func calculateLateralAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5) -> AlignmentStatus {
        
        guard points.count >= 2 else {
            return .notDetected
        }
        
        let firstPoint = points[0]  // Could be shoulder or elbow depending on detection
        let wrist = points[1]
        
        // Calculate average X position of first point and wrist
        let averageX = (firstPoint.x + wrist.x) / 2
        
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