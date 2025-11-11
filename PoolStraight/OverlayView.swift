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
        
        // Determine configuration: 2 points (shoulder, wrist) or 3 points (shoulder, elbow, wrist)
        let hasShoulder = true // First point is always shoulder
        let hasElbow = detectedPoints.count >= 3
        let hasWrist = true // Wrist is always present
        
        let shoulder = convertNormalizedPoint(detectedPoints[0], to: size)
        let elbow = hasElbow ? convertNormalizedPoint(detectedPoints[1], to: size) : nil
        let wrist = convertNormalizedPoint(hasElbow ? detectedPoints[2] : detectedPoints[1], to: size)
        
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
        let modeText = hasElbow ? "3-POINT" : "2-POINT"
        let modeColor = hasElbow ? Color.blue : Color.orange
        context.draw(
            Text(modeText).font(.caption2).bold().foregroundColor(modeColor),
            at: CGPoint(x: size.width - 60, y: 30)
        )
    }
    
    private func convertNormalizedPoint(_ normalizedPoint: CGPoint, to size: CGSize) -> CGPoint {
        return CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }
}