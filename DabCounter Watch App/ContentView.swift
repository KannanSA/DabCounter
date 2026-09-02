import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var pulseCount = false

    var body: some View {
        GeometryReader { geo in
            let ringSize = min(geo.size.width * 0.92, geo.size.height * 0.58)

            VStack(spacing: 4) {
                Spacer(minLength: 0)

                ZStack {
                    ActivityRing(
                        progress: motionManager.ringProgress,
                        color: .dabOrange,
                        lineWidth: max(11, ringSize * 0.11)
                    )

                    VStack(spacing: 0) {
                        Text("\(motionManager.dabCount)")
                            .font(.system(size: ringSize * 0.42, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.35)
                            .lineLimit(1)
                            .scaleEffect(pulseCount ? 1.08 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: pulseCount)
                            .accessibilityIdentifier("dab-count")

                        Text("DABS TODAY")
                            .font(.system(size: max(9, ringSize * 0.085), weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(Color.dabOrange)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .offset(y: 2)
                    .padding(.horizontal, ringSize * 0.2)
                }
                .frame(width: ringSize, height: ringSize)
                .contentShape(Circle())
                .onTapGesture {
                    motionManager.registerManualDab()
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("dab-ring")

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(LastDabFormatter.string(since: motionManager.lastDabDate, now: context.date))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.top, 2)
                .accessibilityLabel(LastDabFormatter.string(since: motionManager.lastDabDate))

                Spacer(minLength: 2)

                HStack(spacing: 8) {
                    Button(action: motionManager.toggleRunning) {
                        Text(motionManager.isRunning ? "Stop" : "Start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(motionManager.isRunning ? Color.gray : Color.dabOrange)
                    .accessibilityIdentifier("start-stop")
                    .accessibilityHint("Starts or stops wrist-motion dab detection")

                    Button(action: motionManager.reset) {
                        Text("Reset")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(white: 0.45))
                    .accessibilityIdentifier("reset")
                    .accessibilityHint("Clears today's dab count")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .controlSize(.small)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .fontDesign(.rounded)
        .background(Color.black)
        .containerBackground(Color.black, for: .navigation)
        .onChange(of: motionManager.dabCount) { _, _ in
            pulseCount = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                pulseCount = false
            }
        }
        .onDisappear {
            motionManager.stop()
        }
    }
}

#Preview("Idle") {
    ContentView()
}
