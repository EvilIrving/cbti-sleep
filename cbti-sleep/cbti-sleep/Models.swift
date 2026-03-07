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

    var timeInBed: TimeInterval? {
        guard let wake = wakeTime else { return nil }
        return wake.timeIntervalSince(bedtime)
    }

    var sleepEfficiency: Double? {
        guard let sleep = sleepDuration, let inBed = timeInBed, inBed > 0 else { return nil }
        return min(max(sleep / inBed, 0), 1)
    }

    var sleepLatencyMinutes: Int? {
        guard let start = sleepStart else { return nil }
        return max(Int(start.timeIntervalSince(bedtime) / 60), 0)
    }

    var formattedBedtime: String {
        Self.timeFormatter.string(from: bedtime)
    }

    var formattedSleepStart: String {
        guard let sleepStart else { return "--:--" }
        return Self.timeFormatter.string(from: sleepStart)
    }

    var formattedWakeTime: String {
        guard let wakeTime else { return "--:--" }
        return Self.timeFormatter.string(from: wakeTime)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
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

// MARK: - Morning Check-in Options

enum SleepQualityOption: String, CaseIterable {
    case poor = "Poor"
    case ok = "OK"
    case good = "Good"
    case great = "Great"

    var numericValue: Int {
        switch self {
        case .poor: return 3
        case .ok: return 5
        case .good: return 7
        case .great: return 9
        }
    }

    init(score: Int) {
        switch score {
        case ..<4:
            self = .poor
        case 4..<6:
            self = .ok
        case 6..<8:
            self = .good
        default:
            self = .great
        }
    }
}

enum FallAsleepOption: String, CaseIterable {
    case underTen = "<10 min"
    case tenToTwenty = "10–20 min"
    case twentyToForty = "20–40 min"
    case overForty = ">40 min"

    var midpointMinutes: Int {
        switch self {
        case .underTen: return 5
        case .tenToTwenty: return 15
        case .twentyToForty: return 30
        case .overForty: return 50
        }
    }
}

enum AwakeningsOption: Int, CaseIterable {
    case zero = 0
    case one = 1
    case two = 2
    case threePlus = 3

    var displayText: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .threePlus: return "3+"
        }
    }

    init(count: Int) {
        switch count {
        case ..<1:
            self = .zero
        case 1:
            self = .one
        case 2:
            self = .two
        default:
            self = .threePlus
        }
    }
}
