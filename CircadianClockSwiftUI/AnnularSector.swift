import SwiftUI

/// A filled donut slice (annular sector) between two radii and two angles.
struct AnnularSector: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat  // 0...1 relative to min(rect.width, rect.height)/2
    var outerRadiusRatio: CGFloat  // 0...1 relative to min(rect.width, rect.height)/2

    func path(in rect: CGRect) -> Path {
        let halfMin = min(rect.width, rect.height) / 2
        let innerRadius = innerRadiusRatio * halfMin
        let outerRadius = outerRadiusRatio * halfMin
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let start = CGFloat(startAngle.radians - .pi / 2) // rotate so 0° is at top
        let end = CGFloat(endAngle.radians - .pi / 2)

        func point(radius: CGFloat, angle: CGFloat) -> CGPoint {
            CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }

        var path = Path()
        let startOuter = point(radius: outerRadius, angle: start)
        path.move(to: startOuter)

        // Outer arc, clockwise from start -> end
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: Double(start)),
            endAngle: Angle(radians: Double(end)),
            clockwise: false
        )

        // Line from outer end to inner end
        let endInner = point(radius: innerRadius, angle: end)
        path.addLine(to: endInner)

        // Inner arc, back from end -> start
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(end)),
            endAngle: Angle(radians: Double(start)),
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}