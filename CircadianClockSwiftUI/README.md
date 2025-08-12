# SwiftUI Circadian Clock

This folder contains a reusable SwiftUI view that renders a circular, clock-like timeline with configurable time-based zones (e.g., Neutral Light, Natural Light). It also shows a live HH:mm:ss clock and a countdown to the end of the current zone.

## Files
- `CircadianClockView.swift`: Main SwiftUI view and models.
- `AnnularSector.swift`: Shape used to draw filled ring segments (donut slices).

## Integration
1. Drag both `.swift` files into your Xcode project.
2. Use the view like below:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        CircadianClockView(
            zones: SampleZones.dayPlan,
            showOuterHalo: true
        )
        .padding(24)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
```

`SampleZones.dayPlan` includes example zones for Sleep, Dim-light, Wind-down, Neutral Light, and Natural Light. Replace with your own configuration using `HH:mm:ss` strings for start and end times.

## Defining zones
Zones are defined with `HH:mm:ss` strings and can wrap across midnight.

```swift
LightZone(
    name: "Natural Light",
    start: .hhmmss("09:30:00"),
    end: .hhmmss("17:30:00"),
    color: .cyan,
    labelColor: .black
)
```

- `start` and `end` are seconds since midnight.
- If `end < start`, the zone is assumed to wrap to the next day.

## Live clock and countdown
The view updates every second. It displays the current time (HH:mm:ss) and the remaining time until the end of the active zone.

## Customization
- `showOuterHalo` toggles a subtle outer ring.
- You can customize colors, thickness, fonts, and labels by editing `CircadianClockView`.

## Minimum deployment target
- iOS 15+. Uses `Canvas`-free APIs for broad compatibility.

## License
MIT