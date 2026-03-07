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

    // MARK: - CBTI Weekly Adjustment

    struct WindowAdjustment {
        let minutes: Int
        let efficiencyPercent: Int
        let message: String
    }

    static func weeklyAdjustment(from entries: [SleepDiaryEntry], currentWindow: SleepWindow?) -> WindowAdjustment? {
        let recent = Array(entries.prefix(7))
        guard recent.count >= 5 else { return nil }

        let eff = efficiency(from: recent)
        let pct = Int(eff * 100)
        let minutes: Int
        if eff > 0.90 { minutes = 15 }
        else if eff < 0.85 { minutes = -15 }
        else { minutes = 0 }

        let message: String
        if minutes > 0 {
            message = "Efficiency \(pct)%. Window +\(minutes) min."
        } else if minutes < 0 {
            message = "Efficiency \(pct)%. Window -\(abs(minutes)) min."
        } else {
            message = "Efficiency \(pct)%. Keep the same window."
        }
        return WindowAdjustment(minutes: minutes, efficiencyPercent: pct, message: message)
    }

    // MARK: - Coach Message

    static func coachMessage(efficiency: Double, entryCount: Int) -> String {
        guard entryCount > 0 else {
            return "Log your sleep to get guidance."
        }
        let pct = Int(efficiency * 100)
        if efficiency > 0.90 {
            return "Efficiency \(pct)%. Sleep is consolidating. Expand the window."
        } else if efficiency >= 0.85 {
            return "Efficiency \(pct)%. On track. Keep this window."
        } else {
            return "Efficiency \(pct)%. Tighten the window to build pressure."
        }
    }

    // MARK: - Aggregate Stats

    static func averageSleepTime(from entries: [SleepDiaryEntry]) -> TimeInterval {
        let durations = entries.compactMap(\.sleepDuration)
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    static func averageAwakenings(from entries: [SleepDiaryEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.nightAwakenings).reduce(0, +)) / Double(entries.count)
    }

    static func driftMessage(for entry: SleepDiaryEntry, plannedWindow: SleepWindow?) -> String? {
        guard let plannedWindow else { return nil }

        let plannedBedMinutes = minutesSinceMidnight(for: plannedWindow.start)
        let plannedWakeMinutes = minutesSinceMidnight(for: plannedWindow.end)
        let actualBedMinutes = minutesSinceMidnight(for: entry.bedtime)
        let actualWakeMinutes = entry.wakeTime.map(minutesSinceMidnight(for:)) ?? plannedWakeMinutes

        if actualBedMinutes - plannedBedMinutes >= 30 {
            return "Bedtime was later than planned. Keep wake time fixed."
        }

        if plannedBedMinutes - actualBedMinutes >= 30 {
            return "Bedtime was earlier than planned. Keep the window stable."
        }

        if abs(actualWakeMinutes - plannedWakeMinutes) >= 30 {
            return "Wake time drifted. Anchor the morning first."
        }

        return nil
    }

    nonisolated private static func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

private extension Array where Element == TimeInterval {
    var average: TimeInterval? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
