import Foundation

struct SleepWindowSuggestion {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

struct SleepDataService {
    static func efficiency(from entries: [SleepDiaryEntry]) -> Double {
        let recent = Array(entries.prefix(14))
        let actualSleep = recent.compactMap(\.sleepDuration).reduce(0, +)
        let timeInBed = recent.compactMap { entry -> TimeInterval? in
            guard let wake = entry.wakeTime else { return nil }
            return wake.timeIntervalSince(entry.bedtime)
        }.reduce(0, +)

        guard timeInBed > 0 else { return 0 }
        return min(max(actualSleep / timeInBed, 0), 1)
    }

    static func streak(from entries: [SleepDiaryEntry]) -> Int {
        let sorted = entries.sorted { $0.date > $1.date }
        var streak = 0
        var referenceDay = Calendar.current.startOfDay(for: Date())

        for entry in sorted {
            let entryDay = entry.date
            if Calendar.current.isDate(entryDay, inSameDayAs: referenceDay) {
                streak += 1
                guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: referenceDay) else { break }
                referenceDay = previousDay
            } else if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: referenceDay),
                      Calendar.current.isDate(entryDay, inSameDayAs: previousDay) {
                streak += 1
                referenceDay = Calendar.current.date(byAdding: .day, value: -1, to: entryDay) ?? entryDay
            } else {
                break
            }
        }

        return streak
    }

    static func suggestedWindow(from entries: [SleepDiaryEntry], wakeTime: Date? = nil) -> SleepWindowSuggestion {
        let durations = entries.compactMap(\.sleepDuration)
        let baseDuration = durations.average ?? 7.5 * 3600
        let clampedDuration = min(max(baseDuration, 4 * 3600), 12 * 3600)
        let targetWake: Date = {
            if let wakeTime { return wakeTime }
            let nextMorning = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: nextMorning) ?? nextMorning
        }()
        let bedtime = targetWake.addingTimeInterval(-clampedDuration)
        return SleepWindowSuggestion(start: bedtime, end: targetWake)
    }

    static func completionRate(for tasks: [DailyTask]) -> Double {
        guard !tasks.isEmpty else { return 0 }
        let completed = tasks.filter(\.isCompleted).count
        return Double(completed) / Double(tasks.count)
    }
}

private extension Array where Element == TimeInterval {
    var average: TimeInterval? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
