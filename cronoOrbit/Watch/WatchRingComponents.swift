import SwiftUI

#if os(watchOS)

/// Arco che rappresenta un impegno sull'anello delle 24 ore.
struct ArcShape: Shape {
    
    let from: Double
    let to: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )
        
        let radius = min(rect.width, rect.height) / 2
        
        let startAngle = Angle(
            degrees: from / 1440.0 * 360.0 - 90
        )
        
        let endAngle = Angle(
            degrees: to / 1440.0 * 360.0 - 90
        )
        
        var path = Path()
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        return path
    }
}


/// Punto che indica l'ora corrente sull'anello.
struct NowDot: View {
    
    let minutes: Double
    
    var body: some View {
        GeometryReader { geometry in
            
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            
            let radius = size / 2
            let angle = minutes / 1440.0 * 2 * Double.pi - Double.pi / 2
            
            let x = geometry.size.width / 2
                + radius * cos(angle)
            
            let y = geometry.size.height / 2
                + radius * sin(angle)
            
            Circle()
                .fill(.white)
                .frame(width: 7, height: 7)
                .shadow(radius: 3)
                .position(x: x, y: y)
        }
    }
}

#endif
