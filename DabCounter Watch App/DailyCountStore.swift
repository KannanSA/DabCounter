import Foundation

/// Persists today's dab count on-device. A new calendar day starts at 0.
struct DailyCountStore {
    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    private enum Key {
        static let count = "dabCount"
        static let day = "dabCountDay"
        static let lastDab = "lastDabDate"
    }

    init(
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
    }

    func load() -> (count: Int, lastDab: Date?) {
        let today = dayStamp(for: now())
        let lastDab = defaults.object(forKey: Key.lastDab) as? Date
        guard defaults.string(forKey: Key.day) == today else {
            defaults.set(0, forKey: Key.count)
            defaults.set(today, forKey: Key.day)
            return (0, lastDab)
        }
        return (defaults.integer(forKey: Key.count), lastDab)
    }

    func save(count: Int, lastDab: Date?) {
        defaults.set(count, forKey: Key.count)
        defaults.set(dayStamp(for: now()), forKey: Key.day)
        if let lastDab {
            defaults.set(lastDab, forKey: Key.lastDab)
        } else {
            defaults.removeObject(forKey: Key.lastDab)
        }
    }

    func dayStamp(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let year = c.year ?? 0
        let month = c.month ?? 0
        let day = c.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
