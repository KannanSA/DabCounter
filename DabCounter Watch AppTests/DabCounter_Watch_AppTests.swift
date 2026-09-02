import Foundation
import Testing
@testable import DabCounter_Watch_App

struct DabDetectorTests {

    @Test func idleMotionDoesNotCount() {
        var detector = DabDetector()
        let counted = detector.process(
            timestamp: 1,
            userAcceleration: (0.02, 0.01, 0.0),
            rotationRate: (0.0, 0.2, 0.0)
        )
        #expect(counted == false)
    }

    @Test func classicDabAxesCountOnce() {
        var detector = DabDetector()
        let first = detector.process(
            timestamp: 1,
            userAcceleration: (2.0, 0, 0),
            rotationRate: (0, 5.0, 0)
        )
        let second = detector.process(
            timestamp: 1.15,
            userAcceleration: (2.0, 0, 0),
            rotationRate: (0, 5.0, 0)
        )
        #expect(first == true)
        #expect(second == false)
    }

    @Test func magnitudeFallbackCountsWhenAxesDoNotMatch() {
        var detector = DabDetector()
        let counted = detector.process(
            timestamp: 1,
            userAcceleration: (0.4, 1.8, 1.4),
            rotationRate: (3.2, 0.2, 3.4)
        )
        #expect(counted == true)
    }

    @Test func countsAgainAfterSettleAndCooldown() {
        var detector = DabDetector()
        #expect(
            detector.process(
                timestamp: 0,
                userAcceleration: (2, 0, 0),
                rotationRate: (0, 5, 0)
            ) == true
        )
        #expect(
            detector.process(
                timestamp: 0.4,
                userAcceleration: (0.05, 0, 0),
                rotationRate: (0, 0.1, 0)
            ) == false
        )
        #expect(
            detector.process(
                timestamp: 1.2,
                userAcceleration: (2, 0, 0),
                rotationRate: (0, 5, 0)
            ) == true
        )
    }

    @Test func walkingLevelMotionIsIgnored() {
        var detector = DabDetector()
        var hits = 0
        for t in stride(from: 0.0, through: 4.0, by: 0.02) {
            let swing = 0.35 * sin(t * 12)
            if detector.process(
                timestamp: t,
                userAcceleration: (swing, 0.15, 0.1),
                rotationRate: (0.2, 0.8, 0.1)
            ) {
                hits += 1
            }
        }
        #expect(hits == 0)
    }
}

struct LastDabFormatterTests {

    @Test func placeholderWhenNeverDabbed() {
        #expect(LastDabFormatter.string(since: nil, now: Date()) == "last dab —")
    }

    @Test func formatsSecondsMinutesHours() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        #expect(LastDabFormatter.string(since: now.addingTimeInterval(-3), now: now) == "last dab 3s ago")
        #expect(LastDabFormatter.string(since: now.addingTimeInterval(-120), now: now) == "last dab 2m ago")
        #expect(LastDabFormatter.string(since: now.addingTimeInterval(-7_200), now: now) == "last dab 2h ago")
        #expect(LastDabFormatter.string(since: now.addingTimeInterval(-172_800), now: now) == "last dab 2d ago")
    }
}

struct DailyCountStoreTests {

    private func makeStore(now: Date, suite: String) -> DailyCountStore {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return DailyCountStore(defaults: defaults, now: { now }, calendar: calendar)
    }

    @Test func newDayStartsAtZeroButKeepsLastDab() {
        let suite = "DabCounterTests.\(UUID().uuidString)"
        let day1 = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14
        let store1 = makeStore(now: day1, suite: suite)
        store1.save(count: 7, lastDab: day1)

        let day2 = Date(timeIntervalSince1970: 1_700_090_000) // next calendar day UTC
        let store2 = DailyCountStore(
            defaults: UserDefaults(suiteName: suite)!,
            now: { day2 },
            calendar: {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                return calendar
            }()
        )
        let loaded = store2.load()
        #expect(loaded.count == 0)
        #expect(loaded.lastDab == day1)
    }

    @Test func sameDayReloadsCount() {
        let suite = "DabCounterTests.\(UUID().uuidString)"
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = makeStore(now: now, suite: suite)
        store.save(count: 4, lastDab: now)
        let loaded = store.load()
        #expect(loaded.count == 4)
        #expect(loaded.lastDab == now)
    }
}

struct MotionManagerTests {

    private func makeManager(suite: String) -> MotionManager {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = DailyCountStore(defaults: defaults)
        return MotionManager(store: store, haptics: {})
    }

    @Test func manualTapIncrementsAndResetClears() {
        let manager = makeManager(suite: "DabCounterMotion.\(UUID().uuidString)")
        #expect(manager.dabCount == 0)
        manager.registerManualDab()
        manager.registerManualDab()
        #expect(manager.dabCount == 2)
        #expect(manager.lastDabDate != nil)
        manager.reset()
        #expect(manager.dabCount == 0)
        #expect(manager.lastDabDate == nil)
    }

    @Test func startStopTogglesSessionWithoutRequiringHardware() {
        let manager = makeManager(suite: "DabCounterMotion.\(UUID().uuidString)")
        manager.start()
        #expect(manager.isRunning == true)
        manager.stop()
        #expect(manager.isRunning == false)
    }

    @Test func ringProgressUsesDailyGoal() {
        let manager = makeManager(suite: "DabCounterMotion.\(UUID().uuidString)")
        for _ in 0..<5 {
            manager.registerManualDab()
        }
        #expect(manager.ringProgress == 0.5)
    }
}
