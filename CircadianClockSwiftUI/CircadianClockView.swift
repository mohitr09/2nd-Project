import SwiftUI

// MARK: - Models

/// A time-based zone rendered as a ring segment on a 24-hour clock.
struct LightZone: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let start: TimeInterval     // seconds since midnight (0...86400)
    let end: TimeInterval       // seconds since midnight (0...86400); if < start, wraps across midnight
    let color: Color
    let labelColor: Color
}

// MARK: - Extensions

extension TimeInterval {
    /// Create seconds since midnight from an `HH:mm:ss` string.
    static func hhmmss(_ string: String) -> TimeInterval {
        let parts = string.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        let hours = parts[0]
        let minutes = parts[1]
        let seconds = parts[2]
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    /// Normalize to the 0...86400 range.
    func clampedDay() -> TimeInterval {
        var value = self
        while value < 0 { value += 86400 }
        while value >= 86400 { value -= 86400 }
        return value
    }
}

extension Date {
    /// Seconds since midnight for this date, using the current calendar/timezone.
    var secondsSinceMidnight: TimeInterval {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute, .second], from: self)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let s = comps.second ?? 0
        return TimeInterval(h * 3600 + m * 60 + s)
    }
}

// MARK: - Utilities

fileprivate func angle(for seconds: TimeInterval) -> Angle {
    let fraction = seconds.clampedDay() / 86400.0
    return Angle(degrees: fraction * 360.0)
}

fileprivate func contains(_ seconds: TimeInterval, in zone: LightZone) -> Bool {
    let s = seconds.clampedDay()
    if zone.end == zone.start { return false }
    if zone.end > zone.start {
        // normal, same-day
        return s >= zone.start && s < zone.end
    } else {
        // wraps midnight
        return s >= zone.start || s < zone.end
    }
}

fileprivate func secondsUntilZoneEnd(from seconds: TimeInterval, zone: LightZone) -> TimeInterval {
    let s = seconds.clampedDay()
    if zone.end > zone.start {
        return max(0, zone.end - s)
    } else {
        // wraps midnight
        return s < zone.end ? max(0, zone.end - s) : (86400 - s + zone.end)
    }
}

fileprivate func formatHMS(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

// MARK: - View

struct CircadianClockView: View {
    let zones: [LightZone]
    var showOuterHalo: Bool = true

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Visual constants
    private let ringOuter: CGFloat = 0.95
    private let ringInner: CGFloat = 0.68
    private let labelRadius: CGFloat = 0.99

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                // Outer white halo
                if showOuterHalo {
                    Circle()
                        .stroke(Color.white.opacity(0.85), lineWidth: size * 0.06)
                        .frame(width: size, height: size)
                }

                // Zone segments
                ForEach(zones) { zone in
                    AnnularSector(
                        startAngle: angle(for: zone.start),
                        endAngle: angle(for: zone.end),
                        innerRadiusRatio: ringInner,
                        outerRadiusRatio: ringOuter
                    )
                    .fill(zone.color)
                }

                // Zone labels placed at arc midpoints
                ForEach(zones) { zone in
                    let midSeconds: TimeInterval = {
                        // Handle wrapping by finding midpoint along the arc length
                        let span = zone.end > zone.start ? (zone.end - zone.start)
                                                         : (86400 - zone.start + zone.end)
                        let mid = (zone.start + span / 2).clampedDay()
                        return mid
                    }()
                    let a = angle(for: midSeconds)

                    Text(zone.name)
                        .font(.system(size: size * 0.05, weight: .semibold))
                        .foregroundColor(zone.labelColor)
                        .rotationEffect(a)
                        .offset(x: 0, y: -size * (labelRadius / 2))
                        .rotationEffect(-a) // keep text upright
                }

                // Current time pointer
                let currentAngle = angle(for: now.secondsSinceMidnight)
                TrianglePointer()
                    .fill(Color.white)
                    .frame(width: size * 0.06, height: size * 0.06)
                    .rotationEffect(currentAngle)
                    .offset(x: 0, y: -size * (ringOuter / 2) - size * 0.01)

                // Inner dial
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.58, height: size * 0.58)
                    .overlay(innerContent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onReceive(timer) { newValue in
            now = newValue
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var innerContent: some View {
        let currentSeconds = now.secondsSinceMidnight
        let activeZone = zones.first(where: { contains(currentSeconds, in: $0) })
        let remaining = activeZone.map { secondsUntilZoneEnd(from: currentSeconds, zone: $0) } ?? 0

        VStack(spacing: 8) {
            if let zone = activeZone {
                Text("Window closes in")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text(formatHMS(remaining))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(zone.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("Current time")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text(formatHMS(currentSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("—")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Pointer Shape

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Sample Data & Preview

enum SampleZones {
    static let dayPlan: [LightZone] = [
        LightZone(name: "Sleep", start: .hhmmss("22:30:00"), end: .hhmmss("06:30:00"), color: Color.purple.opacity(0.9), labelColor: .white),
        LightZone(name: "Dim-light", start: .hhmmss("21:00:00"), end: .hhmmss("22:30:00"), color: Color.purple.opacity(0.7), labelColor: .white),
        LightZone(name: "Wind-Down", start: .hhmmss("20:00:00"), end: .hhmmss("21:00:00"), color: Color.purple.opacity(0.5), labelColor: .white),
        LightZone(name: "Neutral Light", start: .hhmmss("06:30:00"), end: .hhmmss("09:30:00"), color: Color.gray.opacity(0.6), labelColor: .white),
        LightZone(name: "Natural Light", start: .hhmmss("09:30:00"), end: .hhmmss("17:30:00"), color: Color.cyan.opacity(0.8), labelColor: .black)
    ]
}

struct CircadianClockView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CircadianClockView(zones: SampleZones.dayPlan)
                .padding(24)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
            CircadianClockView(zones: SampleZones.dayPlan, showOuterHalo: false)
                .padding(24)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
        }
    }
}