import Foundation

enum LastDabFormatter {
    static func string(since lastDab: Date?, now: Date = Date()) -> String {
        guard let lastDab else { return "last dab —" }

        let seconds = Int(now.timeIntervalSince(lastDab))
        if seconds < 0 { return "last dab 0s ago" }
        if seconds < 60 { return "last dab \(seconds)s ago" }

        let minutes = seconds / 60
        if minutes < 60 { return "last dab \(minutes)m ago" }

        let hours = minutes / 60
        if hours < 24 { return "last dab \(hours)h ago" }

        return "last dab \(hours / 24)d ago"
    }
}
