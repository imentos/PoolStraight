import SwiftUI

struct OverlayView: View {
    let detectedPoints: [CGPoint]
    let alignmentStatus: AlignmentStatus
    let geometryProxy: GeometryProxy
    
    var body: some View {
        Canvas { context, size in
            // Draw fixed center line
            drawCenterLine(context: context, size: size)
            
            // Draw detected points and connections
            if !detectedPoints.isEmpty {
                drawLandmarks(context: context, size: size)
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through to underlying views
    }
    
    private func drawCenterLine(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let startPoint = CGPoint(x: centerX, y: 0)
        let endPoint = CGPoint(x: centerX, y: size.height)
        
        var path = Path()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        context.stroke(
            path,
            with: .color(.white.opacity(0.7)),
            style: StrokeStyle(lineWidth: 2, dash: [10, 5])
        )
    }
    
    private func drawLandmarks(context: GraphicsContext, size: CGSize) {
        guard detectedPoints.count >= 2 else { return }
        
        // Parse detected points (flexible format)
        var armPoints: [CGPoint] = []
        var headPoints: [CGPoint] = []
        
        // Always start with shoulder
        armPoints.append(detectedPoints[0]) // shoulder
        
        // Parse the rest based on point count and positioning
        if detectedPoints.count == 2 {
            // [shoulder, wrist]
            armPoints.append(detectedPoints[1])
        } else if detectedPoints.count == 3 {
            // Could be [shoulder, elbow, wrist] or [shoulder, wrist, leftEye]
            let secondPoint = detectedPoints[1]
            let thirdPoint = detectedPoints[2]
            
            if secondPoint.y < thirdPoint.y {
                // shoulder-elbow-wrist configuration
                armPoints.append(secondPoint) // elbow
                armPoints.append(thirdPoint)  // wrist
            } else {
                // shoulder-wrist-eye configuration
                armPoints.append(secondPoint) // wrist
                headPoints.append(thirdPoint) // leftEye
            }
        } else {
            // More complex with head points
            armPoints.append(detectedPoints[1]) // could be elbow or wrist
            if detectedPoints.count >= 3 && detectedPoints[1].y < detectedPoints[2].y {
                armPoints.append(detectedPoints[2]) // wrist
                // Rest are head points
                for i in 3..<detectedPoints.count {
                    headPoints.append(detectedPoints[i])
                }
            } else {
                // Second point is wrist, rest are head points
                for i in 2..<detectedPoints.count {
                    headPoints.append(detectedPoints[i])
                }
            }
        }
        
        // Extract points for drawing
        let shoulder = convertNormalizedPoint(armPoints[0], to: size)
        let elbow = armPoints.count >= 3 ? convertNormalizedPoint(armPoints[1], to: size) : nil
        let wrist = convertNormalizedPoint(armPoints.last!, to: size)
        
        // Choose color based on alignment status
        let pointColor: Color
        let lineColor: Color
        
        switch alignmentStatus {
        case .aligned:
            pointColor = .green
            lineColor = .green
        case .misaligned:
            pointColor = .red
            lineColor = .red
        case .notDetected:
            pointColor = .gray
            lineColor = .gray
        }
        
        // Draw main alignment line (shoulder to wrist) - this is always the primary reference
        var mainLinePath = Path()
        mainLinePath.move(to: shoulder)
        mainLinePath.addLine(to: wrist)
        
        context.stroke(
            mainLinePath,
            with: .color(lineColor),
            style: StrokeStyle(lineWidth: 6, lineCap: .round)
        )
        
        // If elbow is detected, draw the arm segments with thinner lines
        if let elbow = elbow {
            // Draw shoulder-to-elbow segment (dimmed)
            var shoulderElbowPath = Path()
            shoulderElbowPath.move(to: shoulder)
            shoulderElbowPath.addLine(to: elbow)
            
            context.stroke(
                shoulderElbowPath,
                with: .color(lineColor.opacity(0.6)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            
            // Draw elbow-to-wrist segment (dimmed)
            var elbowWristPath = Path()
            elbowWristPath.move(to: elbow)
            elbowWristPath.addLine(to: wrist)
            
            context.stroke(
                elbowWristPath,
                with: .color(lineColor.opacity(0.6)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
        }
        
        // Draw head tilt indicator if head points are available
        if headPoints.count >= 2 {
            let leftEyeScreen = convertNormalizedPoint(headPoints[0], to: size)
            let rightEyeScreen = convertNormalizedPoint(headPoints[1], to: size)
            
            // Draw head level line
            var headLinePath = Path()
            headLinePath.move(to: leftEyeScreen)
            headLinePath.addLine(to: rightEyeScreen)
            
            // Calculate head tilt for color coding
            let eyeDeltaX = rightEyeScreen.x - leftEyeScreen.x
            let eyeDeltaY = rightEyeScreen.y - leftEyeScreen.y
            let headTiltRadians = atan2(eyeDeltaY, eyeDeltaX)
            var headTiltDegrees = headTiltRadians * 180.0 / Double.pi
            
            // Normalize angle
            if headTiltDegrees > 90 {
                headTiltDegrees = headTiltDegrees - 180
            } else if headTiltDegrees < -90 {
                headTiltDegrees = headTiltDegrees + 180
            }
            
            let isHeadLevel = abs(headTiltDegrees) <= 10.0 // Beginner threshold
            let headColor = isHeadLevel ? Color.cyan : Color.orange
            
            context.stroke(
                headLinePath,
                with: .color(headColor),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            
            // Draw eye points
            context.fill(
                Path(ellipseIn: CGRect(x: leftEyeScreen.x - 6, y: leftEyeScreen.y - 6, width: 12, height: 12)),
                with: .color(headColor)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: rightEyeScreen.x - 6, y: rightEyeScreen.y - 6, width: 12, height: 12)),
                with: .color(headColor)
            )
            
            // Add head tilt indicator text
            let tiltText = isHeadLevel ? "HEAD LEVEL ✓" : "HEAD TILTED ⚠️"
            context.draw(
                Text(tiltText).font(.caption2).bold().foregroundColor(headColor),
                at: CGPoint(x: (leftEyeScreen.x + rightEyeScreen.x) / 2, y: min(leftEyeScreen.y, rightEyeScreen.y) - 20)
            )
        }
        
        // Draw shoulder point
        context.fill(
            Path(ellipseIn: CGRect(
                x: shoulder.x - 10,
                y: shoulder.y - 10,
                width: 20,
                height: 20
            )),
            with: .color(pointColor)
        )
        
        // Draw shoulder label
        context.draw(Text("SHOULDER").font(.caption).bold().foregroundColor(.white), at: CGPoint(x: shoulder.x, y: shoulder.y - 25))
        
        // Draw elbow point if detected
        if let elbow = elbow {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: elbow.x - 8,
                    y: elbow.y - 8,
                    width: 16,
                    height: 16
                )),
                with: .color(pointColor.opacity(0.8))
            )
            
            // Draw elbow label
            context.draw(Text("ELBOW").font(.caption2).foregroundColor(.white.opacity(0.8)), at: CGPoint(x: elbow.x + 20, y: elbow.y))
        }
        
        // Draw wrist point (most important for cue alignment)
        context.fill(
            Path(ellipseIn: CGRect(
                x: wrist.x - 15,
                y: wrist.y - 15,
                width: 30,
                height: 30
            )),
            with: .color(pointColor)
        )
        
        // Draw wrist label with cue indication
        context.draw(Text("CUE GRIP").font(.caption).bold().foregroundColor(.white), at: CGPoint(x: wrist.x, y: wrist.y + 35))
        
        // Add detection mode indicator
        var modeText = armPoints.count == 3 ? "3-POINT" : "2-POINT"
        if headPoints.count >= 2 {
            modeText += "+HEAD"
        }
        let modeColor = headPoints.count >= 2 ? Color.cyan : (armPoints.count == 3 ? Color.blue : Color.orange)
        context.draw(
            Text(modeText).font(.caption2).bold().foregroundColor(modeColor),
            at: CGPoint(x: size.width - 80, y: 30)
        )
    }
    
    private func convertNormalizedPoint(_ normalizedPoint: CGPoint, to size: CGSize) -> CGPoint {
        return CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }
}