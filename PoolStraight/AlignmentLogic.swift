import Foundation
import CoreGraphics

struct AlignmentLogic {
    
    /// Calculates alignment status based on elbow and wrist positions relative to center line
    /// - Parameters:
    ///   - points: Array containing elbow (index 0) and wrist (index 1) coordinates (normalized 0-1)
    ///   - centerLineX: X-coordinate of the center line (normalized, typically 0.5)
    /// - Returns: AlignmentStatus indicating if the arm alignment is correct
    static func calculateAlignment(points: [CGPoint], centerLineX: CGFloat = 0.5) -> AlignmentStatus {
        
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
        
        // Use combined approach: both angle and lateral deviation
        let angleAlignment = calculateAngleAlignment(elbow: elbow, wrist: wrist)
        let lateralAlignment = calculateLateralAlignment(elbow: elbow, wrist: wrist, centerLineX: centerLineX)
        
        // Both conditions must be met for perfect alignment
        if angleAlignment == .aligned && lateralAlignment == .aligned {
            return .aligned
        } else {
            return .misaligned
        }
    }
    
    private static func calculateAngleAlignment(elbow: CGPoint, wrist: CGPoint) -> AlignmentStatus {
        // Calculate angle of the line formed by elbow and wrist
        let deltaY = wrist.y - elbow.y
        let deltaX = wrist.x - elbow.x
        
        // Ensure wrist is below elbow (proper positioning for billiard stance)
        guard deltaY > 0 else {
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
        
        // More forgiving threshold for real pose detection (±8 degrees instead of 5)
        // Real human pose detection has more variance than mock data
        let alignmentThreshold: Double = 8.0
        
        return angleDifferenceInDegrees <= alignmentThreshold ? .aligned : .misaligned
    }
    
    private static func calculateLateralAlignment(elbow: CGPoint, wrist: CGPoint, centerLineX: CGFloat) -> AlignmentStatus {
        // For billiard stance, the wrist position is most important for cue alignment
        // We'll weight the wrist position more heavily than the elbow
        let elbowWeight: CGFloat = 0.3
        let wristWeight: CGFloat = 0.7
        
        let weightedX = (elbow.x * elbowWeight) + (wrist.x * wristWeight)
        
        // Calculate lateral deviation from center line
        let lateralDeviation = abs(weightedX - centerLineX)
        
        // More forgiving threshold for real pose detection (±0.08 = 8% of screen width)
        // Real human pose detection needs more tolerance than mock data
        let lateralThreshold: CGFloat = 0.08
        
        return lateralDeviation <= lateralThreshold ? .aligned : .misaligned
    }
    
    private static func isValidPoint(_ point: CGPoint) -> Bool {
        return point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1
    }
    
    /// Legacy method for simpler lateral-only alignment
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