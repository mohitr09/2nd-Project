import SwiftUI

struct ContentView: View {
    private let zones: [LightZone] = {
        let neutral = LightZone(
            name: "Neutral Light",
            color: Color.orange.opacity(0.9),
            start: try! TimeOfDay.from(hhmmss: "06:30:00"),
            end: try! TimeOfDay.from(hhmmss: "09:00:00")
        )
        let natural = LightZone(
            name: "Natural Light",
            color: Color.blue.opacity(0.85),
            start: try! TimeOfDay.from(hhmmss: "09:00:00"),
            end: try! TimeOfDay.from(hhmmss: "16:30:00")
        )
        let windDown = LightZone(
            name: "Wind-Down",
            color: Color.purple.opacity(0.8),
            start: try! TimeOfDay.from(hhmmss: "20:30:00"),
            end: try! TimeOfDay.from(hhmmss: "22:00:00")
        )
        let sleep = LightZone(
            name: "Sleep",
            color: Color.indigo.opacity(0.85),
            start: try! TimeOfDay.from(hhmmss: "22:00:00"),
            end: try! TimeOfDay.from(hhmmss: "06:30:00")
        )
        return [neutral, natural, windDown, sleep]
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                CircadianDialView(zones: zones)
                    .frame(maxWidth: 480)
                Text("Zones are configured with HH:mm:ss strings and support crossing midnight.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Circadian Dial")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}