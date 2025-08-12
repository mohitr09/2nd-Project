import SwiftUI

// MARK: - TimeOfDay

/// Represents a wall-clock time within a single day with second precision.
/// Provides parsing from "HH:mm:ss" and conversion to angles on a 24h dial.
public struct TimeOfDay: Hashable, Codable, Comparable {
    public let secondsSinceMidnight: Int

    public init(secondsSinceMidnight: Int) {
        let clamped = max(0, min(86_399, secondsSinceMidnight))
        self.secondsSinceMidnight = clamped
    }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.secondsSinceMidnight < rhs.secondsSinceMidnight
    }

    public static func from(hhmmss: String) throws -> TimeOfDay {
        enum ParseError: Error { case invalidFormat }
        let parts = hhmmss.split(separator: ":").map { String($0) }
        guard parts.count == 3,
              let h = Int(parts[0]), let m = Int(parts[1]), let s = Int(parts[2]),
              (0...23).contains(h), (0...59).contains(m), (0...59).contains(s) else {
            throw ParseError.invalidFormat
        }
        return TimeOfDay(secondsSinceMidnight: h * 3600 + m * 60 + s)
    }

    public static func now(in timeZone: TimeZone = .current) -> TimeOfDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.hour, .minute, .second], from: Date())
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let s = comps.second ?? 0
        return TimeOfDay(secondsSinceMidnight: h * 3600 + m * 60 + s)
    }

    /// Angle on a 24-hour dial, where 00:00:00 is at -90° (12 o'clock) and increases clockwise.
    public var dialAngle: Angle {
        let fractionOfDay = Double(secondsSinceMidnight) / 86_400.0
        return Angle(degrees: fractionOfDay * 360.0 - 90.0)
    }

    public var stringHHmmss: String {
        let h = secondsSinceMidnight / 3600
        let m = (secondsSinceMidnight % 3600) / 60
        let s = secondsSinceMidnight % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - LightZone

/// A labeled time range rendered as a colored ring segment on the dial.
public struct LightZone: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let color: Color
    public let start: TimeOfDay
    public let end: TimeOfDay

    public init(name: String, color: Color, start: TimeOfDay, end: TimeOfDay) {
        self.name = name
        self.color = color
        self.start = start
        self.end = end
    }
}

// MARK: - Shapes

/// Circular ring segment between two angles (clockwise), drawn as a stroke of a specified thickness.
struct RingSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let size = min(rect.width, rect.height)
        let radius = size / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: center,
                 radius: radius,
                 startAngle: startAngle,
                 endAngle: endAngle,
                 clockwise: false)
        return p
    }
}

// MARK: - CircadianDialView

public struct CircadianDialView: View {
    public struct Config {
        public var ringThickness: CGFloat = 24
        public var backgroundRingColor: Color = Color(.systemGray6)
        public var tickColor: Color = .secondary
        public var showTicks: Bool = true
        public var showZoneLabels: Bool = true
        public var labelFont: Font = .caption
        public var innerContentPadding: CGFloat = 28
        public init() {}
    }

    private let zones: [LightZone]
    private let config: Config
    private let timeZone: TimeZone

    @State private var now: TimeOfDay = .now()

    public init(zones: [LightZone], config: Config = .init(), timeZone: TimeZone = .current) {
        self.zones = zones
        self.config = config
        self.timeZone = timeZone
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background ring
                Circle()
                    .stroke(config.backgroundRingColor, lineWidth: config.ringThickness)

                // Optional hour ticks
                if config.showTicks { ticksLayer(size: min(geo.size.width, geo.size.height)) }

                // Zone segments
                ForEach(zoneSegments()) { seg in
                    RingSegment(startAngle: seg.start, endAngle: seg.end)
                        .stroke(seg.color, style: StrokeStyle(lineWidth: config.ringThickness, lineCap: .round))
                }

                // Zone labels
                if config.showZoneLabels {
                    ForEach(zoneMidpoints()) { item in
                        label(for: item.name,
                              at: item.angle,
                              in: geo.size,
                              color: item.color)
                    }
                }

                // Current time pointer
                pointer(in: geo.size)

                // Inner live clock
                VStack(spacing: 6) {
                    Text(now.stringHHmmss)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("Current Time")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(config.innerContentPadding)
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                now = TimeOfDay.now(in: timeZone)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }

    // MARK: - Layers

    private func ticksLayer(size: CGFloat) -> some View {
        let tickCount = 24
        let radius = size / 2
        return ZStack {
            ForEach(0..<tickCount, id: \.self) { i in
                let angle = Angle(degrees: (Double(i) / 24.0) * 360.0 - 90.0)
                Capsule()
                    .fill(config.tickColor)
                    .frame(width: 2, height: i % 6 == 0 ? 14 : 8)
                    .offset(x: 0, y: -(radius - config.ringThickness / 2 - 6))
                    .rotationEffect(angle)
            }
        }
    }

    private func pointer(in size: CGSize) -> some View {
        let radius = min(size.width, size.height) / 2
        let angle = now.dialAngle
        return TrianglePointer()
            .fill(Color.accentColor)
            .frame(width: 14, height: 10)
            .offset(x: 0, y: -(radius - config.ringThickness / 2))
            .rotationEffect(angle)
            .shadow(radius: 1)
    }

    private func label(for text: String, at angle: Angle, in size: CGSize, color: Color) -> some View {
        let radius = min(size.width, size.height) / 2
        let distance = radius - config.ringThickness - 8
        return Text(text)
            .font(config.labelFont)
            .foregroundStyle(color)
            .padding(4)
            .background(.ultraThinMaterial, in: Capsule())
            .offset(x: CGFloat(cos(angle.radians)) * distance, y: CGFloat(sin(angle.radians)) * distance)
            .rotationEffect(angle + Angle(degrees: 90))
    }

    // MARK: - Zone geometry helpers

    private struct Segment: Identifiable { let id = UUID(); let start: Angle; let end: Angle; let color: Color }
    private struct Midpoint: Identifiable { let id = UUID(); let angle: Angle; let name: String; let color: Color }

    private func zoneSegments() -> [Segment] {
        zones.flatMap { zone in
            let startAngle = zone.start.dialAngle
            let endAngle = zone.end.dialAngle

            // If the range crosses midnight, draw two pieces: start->24h and 0h->end
            if zone.end.secondsSinceMidnight <= zone.start.secondsSinceMidnight {
                let endOfDay = Angle(degrees: 270) // 24:00 which maps to -90 + 360 = 270
                let startOfDay = Angle(degrees: -90)
                return [
                    Segment(start: startAngle, end: endOfDay, color: zone.color),
                    Segment(start: startOfDay, end: endAngle, color: zone.color)
                ]
            } else {
                return [Segment(start: startAngle, end: endAngle, color: zone.color)]
            }
        }
    }

    private func zoneMidpoints() -> [Midpoint] {
        zones.map { zone in
            let start = Double(zone.start.secondsSinceMidnight)
            var end = Double(zone.end.secondsSinceMidnight)
            if end <= start { end += 86_400 }
            let mid = (start + end) / 2.0
            let normalized = mid.truncatingRemainder(dividingBy: 86_400)
            let fraction = normalized / 86_400
            let angle = Angle(degrees: fraction * 360 - 90)
            return Midpoint(angle: angle, name: zone.name, color: zone.color)
        }
    }
}

// MARK: - Pointer shape

struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Preview scaffolding

struct CircadianDialView_Previews: PreviewProvider {
    static var previews: some View {
        let zones: [LightZone] = [
            LightZone(
                name: "Neutral Light",
                color: Color.orange.opacity(0.9),
                start: try! .from(hhmmss: "06:30:00"),
                end: try! .from(hhmmss: "09:00:00")
            ),
            LightZone(
                name: "Natural Light",
                color: Color.blue.opacity(0.85),
                start: try! .from(hhmmss: "09:00:00"),
                end: try! .from(hhmmss: "16:30:00")
            ),
            LightZone(
                name: "Wind-Down",
                color: Color.purple.opacity(0.8),
                start: try! .from(hhmmss: "20:30:00"),
                end: try! .from(hhmmss: "22:00:00")
            ),
            LightZone(
                name: "Sleep",
                color: Color.indigo.opacity(0.85),
                start: try! .from(hhmmss: "22:00:00"),
                end: try! .from(hhmmss: "06:30:00") // crosses midnight
            )
        ]

        return CircadianDialView(zones: zones)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}