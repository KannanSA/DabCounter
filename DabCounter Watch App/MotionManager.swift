import Foundation
import Combine
import CoreMotion
import WatchKit

/// Session + CoreMotion hook. Manual taps always count; motion counts while running.
final class MotionManager: ObservableObject {
    static let dailyGoal = 10

    @Published private(set) var dabCount: Int = 0
    @Published private(set) var lastDabDate: Date?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isMotionAvailable: Bool = false

    private let deviceMotion = CMMotionManager()
    private var detector = DabDetector()
    private let store: DailyCountStore
    private let now: () -> Date
    private let haptics: () -> Void

    var ringProgress: Double {
        Double(dabCount) / Double(Self.dailyGoal)
    }

    init(
        store: DailyCountStore = DailyCountStore(),
        now: @escaping () -> Date = Date.init,
        haptics: @escaping () -> Void = {
            WKInterfaceDevice.current().play(.success)
        }
    ) {
        self.store = store
        self.now = now
        self.haptics = haptics
        isMotionAvailable = deviceMotion.isDeviceMotionAvailable
        let loaded = store.load()
        dabCount = loaded.count
        lastDabDate = loaded.lastDab
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        detector.resetCycle()
        startMotionUpdates()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        stopMotionUpdates()
    }

    func toggleRunning() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func reset() {
        dabCount = 0
        lastDabDate = nil
        detector = DabDetector()
        persist()
    }

    /// Tap-to-count path (simulator, or when a dab should be entered by hand).
    func registerManualDab() {
        registerDab()
    }

    func stopMotionUpdates() {
        deviceMotion.stopDeviceMotionUpdates()
    }

    private func startMotionUpdates() {
        isMotionAvailable = deviceMotion.isDeviceMotionAvailable
        guard deviceMotion.isDeviceMotionAvailable else { return }

        deviceMotion.deviceMotionUpdateInterval = 1.0 / 50.0
        deviceMotion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.handleDeviceMotion(data)
        }
    }

    private func handleDeviceMotion(_ data: CMDeviceMotion) {
        let acceleration = data.userAcceleration
        let rotation = data.rotationRate
        let didDab = detector.process(
            timestamp: data.timestamp,
            userAcceleration: (acceleration.x, acceleration.y, acceleration.z),
            rotationRate: (rotation.x, rotation.y, rotation.z)
        )
        if didDab {
            registerDab()
        }
    }

    private func registerDab() {
        dabCount += 1
        lastDabDate = now()
        persist()
        haptics()
    }

    private func persist() {
        store.save(count: dabCount, lastDab: lastDabDate)
    }
}
