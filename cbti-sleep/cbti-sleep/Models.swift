import Foundation
import SwiftData

@Model
final class SleepDiaryEntry {
    var date: Date
    var bedtime: Date
    var sleepStart: Date?
    var wakeTime: Date?
    var sleepQuality: Int
    var caffeineIntake: Bool
    var screenTimeMinutes: Int
    var nightAwakenings: Int
    var moodRating: Int
    var notes: String?

    init(
        date: Date,
        bedtime: Date,
        sleepStart: Date? = nil,
        wakeTime: Date? = nil,
        sleepQuality: Int,
        caffeineIntake: Bool,
        screenTimeMinutes: Int,
        nightAwakenings: Int,
        moodRating: Int,
        notes: String? = nil
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.bedtime = bedtime
        self.sleepStart = sleepStart
        self.wakeTime = wakeTime
        self.sleepQuality = sleepQuality
        self.caffeineIntake = caffeineIntake
        self.screenTimeMinutes = screenTimeMinutes
        self.nightAwakenings = nightAwakenings
        self.moodRating = moodRating
        self.notes = notes
    }

    var sleepDuration: TimeInterval? {
        guard let start = sleepStart, let wake = wakeTime else { return nil }
        return wake.timeIntervalSince(start)
    }

    var formattedDuration: String {
        guard let duration = sleepDuration else { return "--" }
        return "\(Int(duration / 3600))h \(Int(duration.truncatingRemainder(dividingBy: 3600) / 60))m"
    }
}

@Model
final class SleepWindow {
    var start: Date
    var end: Date
    var label: String

    init(start: Date, end: Date, label: String = "CBTI 推荐窗口") {
        self.start = start
        self.end = end
        self.label = label
    }

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

@Model
final class DailyTask {
    var title: String
    var subtitle: String
    var isCompleted: Bool
    var dueTime: Date?

    init(title: String, subtitle: String, isCompleted: Bool = false, dueTime: Date? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.dueTime = dueTime
    }
}

@Model
final class CBTISessionConfig {
    var startDate: Date
    var durationWeeks: Int
    var completedDays: Int

    init(startDate: Date, durationWeeks: Int, completedDays: Int = 0) {
        self.startDate = startDate
        self.durationWeeks = durationWeeks
        self.completedDays = completedDays
    }
}
