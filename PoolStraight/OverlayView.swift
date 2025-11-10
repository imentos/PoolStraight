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
        
        let elbow = convertNormalizedPoint(detectedPoints[0], to: size)
        let wrist = convertNormalizedPoint(detectedPoints[1], to: size)
        
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
        
        // Draw connection line between elbow and wrist
        var linePath = Path()
        linePath.move(to: elbow)
        linePath.addLine(to: wrist)
        
        context.stroke(
            linePath,
            with: .color(lineColor),
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        
        // Draw elbow point (larger and more visible)
        context.fill(
            Path(ellipseIn: CGRect(
                x: elbow.x - 12,
                y: elbow.y - 12,
                width: 24,
                height: 24
            )),
            with: .color(pointColor)
        )
        
        // Draw elbow label
        context.draw(Text("ELBOW").font(.caption).bold().foregroundColor(.white), at: CGPoint(x: elbow.x, y: elbow.y - 30))
        
        // Draw wrist point (slightly larger since it's more important for cue alignment)
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
    }
    
    private func convertNormalizedPoint(_ normalizedPoint: CGPoint, to size: CGSize) -> CGPoint {
        return CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }
}