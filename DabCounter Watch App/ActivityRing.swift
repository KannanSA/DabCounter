import SwiftUI

/// Apple Activity–style circular ring: dim track, round caps, extra laps overlay.
struct ActivityRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 14

    var body: some View {
        let clamped = max(0, progress)
        let laps = Int(clamped)
        let fraction = clamped - Double(laps)
        let visibleFraction: CGFloat = {
            if laps >= 1 {
                return CGFloat(max(fraction, 0.0001))
            }
            return CGFloat(fraction)
        }()

        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.22),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            if laps >= 1 {
                Circle()
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
            }

            if visibleFraction > 0 {
                Circle()
                    .trim(from: 0, to: visibleFraction)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.65), radius: 2.5, y: 0)
            }
        }
        .padding(lineWidth / 2)
        .animation(.easeInOut(duration: 0.28), value: progress)
        .accessibilityHidden(true)
    }
}

extension Color {
    /// Move-ring-adjacent orange used across the watch face.
    static let dabOrange = Color(red: 1.0, green: 0.38, blue: 0.08)
}
