## CircadianDialView (SwiftUI)

A 24-hour circular dial that renders labeled time-range zones (e.g., Neutral Light, Natural Light) with a live ticking digital clock and current-time pointer. Zones are configured with `HH:mm:ss` strings.

### Usage

1. Add `CircadianDialView.swift` to your SwiftUI target.
2. Define your zones:

```swift
let zones: [LightZone] = [
    LightZone(
        name: "Neutral Light",
        color: .orange,
        start: try! TimeOfDay.from(hhmmss: "06:30:00"),
        end: try! TimeOfDay.from(hhmmss: "09:00:00")
    ),
    LightZone(
        name: "Natural Light",
        color: .blue,
        start: try! TimeOfDay.from(hhmmss: "09:00:00"),
        end: try! TimeOfDay.from(hhmmss: "16:30:00")
    ),
    LightZone(
        name: "Sleep",
        color: .indigo,
        start: try! TimeOfDay.from(hhmmss: "22:00:00"),
        end: try! TimeOfDay.from(hhmmss: "06:30:00") // crosses midnight
    )
]
```

3. Show the dial:

```swift
CircadianDialView(zones: zones)
    .frame(width: 320, height: 320)
```

### Notes
- 00:00:00 is at the top; angles increase clockwise.
- Ranges that cross midnight are supported automatically.
- The inner digital clock updates every second; the pointer follows the current time.
- Customize visuals with `CircadianDialView.Config`.