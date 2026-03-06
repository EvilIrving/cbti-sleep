import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepDiaryEntry.date, order: .reverse) var diaryEntries: [SleepDiaryEntry]
    @Query(sort: \DailyTask.title, order: .forward) var tasks: [DailyTask]
    @Query(sort: \SleepWindow.start, order: .reverse) var windows: [SleepWindow]
    @Query var configs: [CBTISessionConfig]

    @State private var showingQuickLog = false
    @State private var quickLogDraft = QuickLogDraft()
    @State private var seededDefaults = false

    private var completionRate: Double { SleepDataService.completionRate(for: tasks) }
    private var efficiency: Double { SleepDataService.efficiency(from: diaryEntries) }
    private var streak: Int { SleepDataService.streak(from: diaryEntries) }

    var body: some View {
        TabView {
            NavigationStack {
                ZStack {
                    AppBackground()
                    ScrollView(.vertical, showsIndicators: false) {
                        HomeDashboardView(
                            tasks: tasks,
                            diaryEntries: diaryEntries,
                            windows: windows,
                            completionRate: completionRate,
                            efficiency: efficiency,
                            streak: streak,
                            toggleTask: toggleTask,
                            onLogTap: { showingQuickLog = true }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                    }
                }
                .navigationBarHidden(true)
                .task { seedDefaultsIfNeeded() }
            }
            .tabItem { Label("首页", systemImage: "moon.stars.fill") }

            NavigationStack {
                ZStack {
                    AppBackground()
                    RecordsView(entries: diaryEntries, addAction: { showingQuickLog = true })
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("记录", systemImage: "square.and.pencil") }

            NavigationStack {
                ZStack {
                    AppBackground()
                    StatsView(entries: diaryEntries, tasks: tasks)
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("进度", systemImage: "chart.bar.fill") }

            NavigationStack {
                ZStack {
                    AppBackground()
                    LessonsView()
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("课程", systemImage: "sparkles.rectangle.stack.fill") }

            NavigationStack {
                ZStack {
                    AppBackground()
                    SettingsView()
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
        }
        .tint(SleepPalette.night)
        .sheet(isPresented: $showingQuickLog) {
            QuickLogSheet(draft: $quickLogDraft) {
                saveQuickLog()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func toggleTask(_ task: DailyTask) {
        task.isCompleted.toggle()
        try? modelContext.save()
    }

    private func seedDefaultsIfNeeded() {
        guard !seededDefaults else { return }
        if tasks.isEmpty {
            let sample = [
                DailyTask(title: "固定起床", subtitle: "06:30 起床，建立节律锚点"),
                DailyTask(title: "睡前准备", subtitle: "22:00 后降低灯光与屏幕刺激", dueTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())),
                DailyTask(title: "完成日记", subtitle: "醒来后 3 分钟内完成记录"),
            ]
            sample.forEach(modelContext.insert)
        }
        if windows.isEmpty {
            let wake = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
            modelContext.insert(SleepWindow(start: wake.addingTimeInterval(-7.5 * 3600), end: wake))
        }
        if configs.isEmpty {
            modelContext.insert(CBTISessionConfig(startDate: Date(), durationWeeks: 12))
        }
        try? modelContext.save()
        seededDefaults = true
    }

    private func saveQuickLog() {
        let entry = SleepDiaryEntry(
            date: quickLogDraft.date,
            bedtime: quickLogDraft.bedtime,
            sleepStart: quickLogDraft.sleepStart,
            wakeTime: quickLogDraft.wakeTime,
            sleepQuality: quickLogDraft.sleepQuality,
            caffeineIntake: quickLogDraft.caffeineIntake,
            screenTimeMinutes: quickLogDraft.screenTimeMinutes,
            nightAwakenings: quickLogDraft.nightAwakenings,
            moodRating: quickLogDraft.moodRating,
            notes: quickLogDraft.notes
        )
        modelContext.insert(entry)
        try? modelContext.save()
        quickLogDraft.reset()
        showingQuickLog = false
    }
}

private enum SleepPalette {
    static let backgroundTop = Color(red: 0.05, green: 0.08, blue: 0.16)
    static let backgroundBottom = Color(red: 0.02, green: 0.03, blue: 0.08)
    static let card = Color.white.opacity(0.06)
    static let cardStrong = Color.white.opacity(0.10)
    static let night = Color(red: 0.86, green: 0.90, blue: 1.00)
    static let indigo = Color(red: 0.46, green: 0.55, blue: 0.96)
    static let lavender = Color(red: 0.64, green: 0.70, blue: 0.96)
    static let yellow = Color(red: 0.72, green: 0.68, blue: 0.94)
    static let green = Color(red: 0.53, green: 0.69, blue: 0.78)
    static let pink = Color(red: 0.64, green: 0.60, blue: 0.86)
    static let textSoft = Color.white.opacity(0.62)
    static let textFaint = Color.white.opacity(0.38)
}

private struct QuickLogDraft {
    var date = Date()
    var bedtime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    var sleepStart = Calendar.current.date(byAdding: .hour, value: -7, to: Date()) ?? Date()
    var wakeTime = Date()
    var sleepQuality = 7
    var caffeineIntake = false
    var screenTimeMinutes = 20
    var nightAwakenings = 1
    var moodRating = 6
    var notes: String?

    mutating func reset() {
        date = Date()
        bedtime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
        sleepStart = Calendar.current.date(byAdding: .hour, value: -7, to: Date()) ?? Date()
        wakeTime = Date()
        sleepQuality = 7
        caffeineIntake = false
        screenTimeMinutes = 20
        nightAwakenings = 1
        moodRating = 6
        notes = nil
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [SleepPalette.backgroundTop, SleepPalette.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(SleepPalette.indigo.opacity(0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 110, y: -70)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(SleepPalette.lavender.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -80, y: 80)
        }
        .ignoresSafeArea()
    }
}

private struct HomeDashboardView: View {
    let tasks: [DailyTask]
    let diaryEntries: [SleepDiaryEntry]
    let windows: [SleepWindow]
    let completionRate: Double
    let efficiency: Double
    let streak: Int
    let toggleTask: (DailyTask) -> Void
    let onLogTap: () -> Void

    private var window: SleepWindow? { windows.first }
    private var suggestion: SleepWindowSuggestion { SleepDataService.suggestedWindow(from: diaryEntries) }
    private var todayTask: DailyTask? { tasks.first(where: { !$0.isCompleted }) ?? tasks.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DashboardHeader()
            HeroSleepCard(window: window, suggestion: suggestion, completionRate: completionRate, streak: streak)
            InsightStrip(efficiency: efficiency, streak: streak, entryCount: diaryEntries.count)
            if let task = todayTask {
                FocusTaskCard(task: task, completionRate: completionRate, toggleTask: toggleTask)
            }
            WeekProgressCard(tasks: tasks)
            SleepPlanCard(window: window, suggestion: suggestion)
            QuickCaptureCard(onTap: onLogTap)
            RecordsOverview(entries: diaryEntries)
        }
    }
}

private struct DashboardHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SleepPalette.textSoft)
                Text("Sleep")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SleepPalette.night)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(SleepPalette.night)
            }
        }
        .padding(.top, 10)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "早安，欢迎回来" }
        if hour < 18 { return "下午好，继续保持" }
        return "晚上好，准备收尾"
    }
}

private struct HeroSleepCard: View {
    let window: SleepWindow?
    let suggestion: SleepWindowSuggestion
    let completionRate: Double
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tonight")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SleepPalette.textSoft)
                    Text(windowText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(SleepPalette.night)
                }
                Spacer()
                VStack(spacing: 10) {
                    GlowOrb()
                    Text("\(Int(completionRate * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(SleepPalette.textSoft)
                }
            }
            HStack(spacing: 10) {
                HeroPill(title: "streak", value: "\(streak)d")
                HeroPill(title: "window", value: durationText)
                HeroPill(title: "wake", value: wakeText)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [SleepPalette.cardStrong, Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var start: Date { window?.start ?? suggestion.start }
    private var end: Date { window?.end ?? suggestion.end }
    private var wakeText: String { shortTime(end) }
    private var windowText: String { "\(shortTime(start)) - \(shortTime(end))" }

    private var durationText: String {
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return "\(hours)h \(minutes)m"
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

private struct GlowOrb: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(SleepPalette.indigo.opacity(0.22))
                .frame(width: 92, height: 92)
                .blur(radius: 12)
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 60, height: 60)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 24))
                .foregroundStyle(SleepPalette.night)
        }
    }
}

private struct HeroPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(SleepPalette.textFaint)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SleepPalette.night)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct InsightStrip: View {
    let efficiency: Double
    let streak: Int
    let entryCount: Int

    var body: some View {
        HStack(spacing: 12) {
            MiniStatCard(title: "eff", value: "\(Int(efficiency * 100))%", tint: SleepPalette.indigo, symbol: "moonphase.waning.gibbous")
            MiniStatCard(title: "streak", value: "\(streak)", tint: SleepPalette.lavender, symbol: "sparkles")
            MiniStatCard(title: "logs", value: "\(entryCount)", tint: SleepPalette.green, symbol: "calendar")
        }
    }
}

private struct MiniStatCard: View {
    let title: String
    let value: String
    let tint: Color
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SleepPalette.night)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(SleepPalette.night)
            Text(title)
                .font(.caption)
                .foregroundStyle(SleepPalette.textSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SleepPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FocusTaskCard: View {
    let task: DailyTask
    let completionRate: Double
    let toggleTask: (DailyTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Now")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(Int(completionRate * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SleepPalette.night)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06), in: Capsule())
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SleepPalette.night)
                    Text(task.subtitle)
                        .font(.footnote)
                        .foregroundStyle(SleepPalette.textSoft)
                }
                Spacer()
                BlobFace(color: SleepPalette.indigo, mood: task.isCompleted ? "moon.fill" : "moon.stars")
            }
            Button {
                toggleTask(task)
            } label: {
                Text(task.isCompleted ? "done" : "complete")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SleepPalette.night)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
        }
        .padding(22)
        .background(SleepPalette.cardStrong, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct BlobFace: View {
    let color: Color
    let mood: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color.opacity(0.14))
                .frame(width: 92, height: 92)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
            Image(systemName: mood)
                .font(.system(size: 28))
                .foregroundStyle(SleepPalette.night)
        }
    }
}

private struct WeekProgressCard: View {
    let tasks: [DailyTask]

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Week")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(completedCount)/7")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SleepPalette.textSoft)
                }
                HStack(spacing: 10) {
                    ForEach(Array(weekStates.enumerated()), id: \.offset) { index, done in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(done ? SleepPalette.indigo.opacity(0.85) : Color.white.opacity(0.06))
                                    .frame(width: 34, height: 34)
                                if done {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(SleepPalette.night)
                                }
                            }
                            Text(dayLabels[index])
                                .font(.caption2)
                                .foregroundStyle(SleepPalette.textSoft)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private let dayLabels = ["一", "二", "三", "四", "五", "六", "日"]
    private var completedCount: Int { min(tasks.filter(\.isCompleted).count, 7) }
    private var weekStates: [Bool] { (0..<7).map { $0 < completedCount } }
}

private struct SleepPlanCard: View {
    let window: SleepWindow?
    let suggestion: SleepWindowSuggestion

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Window")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(SleepPalette.textSoft)
                }
                HStack(spacing: 14) {
                    PlanMetric(title: "就寝", value: timeText(start))
                    PlanMetric(title: "起床", value: timeText(end))
                    PlanMetric(title: "时长", value: durationText)
                }
                Text("wait for sleepiness")
                    .font(.footnote)
                    .foregroundStyle(SleepPalette.textSoft)
            }
        }
    }

    private var start: Date { window?.start ?? suggestion.start }
    private var end: Date { window?.end ?? suggestion.end }
    private var durationText: String {
        let interval = end.timeIntervalSince(start)
        return "\(Int(interval / 3600))h \(Int(interval / 60) % 60)m"
    }

    private func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

private struct PlanMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SleepPalette.textSoft)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(SleepPalette.night)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct QuickCaptureCard: View {
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log")
                .font(.headline.weight(.bold))
                .foregroundStyle(SleepPalette.night)
            Button {
                onTap()
            } label: {
                HStack {
                    Text("record last night")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(SleepPalette.night)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .padding(.horizontal, 2)
            }
        }
        .padding(22)
        .background(SleepPalette.cardStrong, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct RecordsOverview: View {
    let entries: [SleepDiaryEntry]

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(entries.count) 条")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SleepPalette.textSoft)
                }
                if let recent = entries.first {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(dateText(recent.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SleepPalette.night)
                            Text(recent.formattedDuration)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SleepPalette.night)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("quality")
                                .font(.caption)
                                .foregroundStyle(SleepPalette.textSoft)
                            Text("\(recent.sleepQuality)/10")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(SleepPalette.indigo)
                        }
                    }
                } else {
                    Text("no entries yet")
                        .font(.subheadline)
                        .foregroundStyle(SleepPalette.textSoft)
                }
            }
        }
    }

    private func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

private struct RecordsView: View {
    let entries: [SleepDiaryEntry]
    let addAction: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "log", title: "Night notes", subtitle: "keep it simple")
                Button {
                    addAction()
                } label: {
                    HStack {
                        Text("new log")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(SleepPalette.night)
                    .padding(18)
                    .background(SleepPalette.cardStrong, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                ForEach(entries) { entry in
                    DiaryEntryCard(entry: entry)
                }
                if entries.isEmpty {
                    EmptyStateCard(title: "No logs", subtitle: "start tonight", tint: SleepPalette.indigo)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

private struct DiaryEntryCard: View {
    let entry: SleepDiaryEntry

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateText(entry.date))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(SleepPalette.night)
                        Text("\(timeText(entry.sleepStart))  ·  \(timeText(entry.wakeTime))")
                            .font(.subheadline)
                            .foregroundStyle(SleepPalette.textSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(entry.formattedDuration)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(SleepPalette.night)
                        Text("\(entry.sleepQuality)/10")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SleepPalette.indigo)
                    }
                }
                HStack(spacing: 10) {
                    DiaryTag(text: "\(entry.nightAwakenings) wakes", tint: SleepPalette.pink)
                    DiaryTag(text: "\(entry.screenTimeMinutes)m screen", tint: SleepPalette.indigo)
                    if entry.caffeineIntake {
                        DiaryTag(text: "caffeine", tint: SleepPalette.green)
                    }
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(SleepPalette.textSoft)
                }
            }
        }
    }

    private func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func timeText(_ date: Date?) -> String {
        guard let date else { return "--" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

private struct DiaryTag: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(SleepPalette.night)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(tint.opacity(0.35), in: Capsule())
    }
}

private struct StatsView: View {
    let entries: [SleepDiaryEntry]
    let tasks: [DailyTask]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "progress", title: "Soft trends", subtitle: "less pressure")
                SleepCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("last 7 nights")
                                .font(.headline.weight(.bold))
                            Spacer()
                            Text("week")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SleepPalette.night)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06), in: Capsule())
                        }
                        TrendBars(entries: Array(entries.prefix(7).reversed()))
                    }
                }
                HStack(spacing: 12) {
                    MiniStatCard(title: "tasks", value: "\(Int(SleepDataService.completionRate(for: tasks) * 100))%", tint: SleepPalette.indigo, symbol: "checkmark.seal.fill")
                    MiniStatCard(title: "sleep", value: "\(Int(SleepDataService.efficiency(from: entries) * 100))%", tint: SleepPalette.green, symbol: "bed.double.fill")
                }
                SleepCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("next")
                            .font(.headline.weight(.bold))
                        Text("expand the window slowly when sleep feels stable")
                            .font(.footnote)
                            .foregroundStyle(SleepPalette.textSoft)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

private struct TrendBars: View {
    let entries: [SleepDiaryEntry]

    var body: some View {
        let values = entries.map(\.sleepQuality)
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 8) {
                    Text("\(value)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(SleepPalette.textSoft)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(index == values.count - 1 ? SleepPalette.indigo : SleepPalette.lavender)
                        .frame(height: max(CGFloat(value) * 12, 24))
                    Text(shortDay(index))
                        .font(.caption2)
                        .foregroundStyle(SleepPalette.textSoft)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 170, alignment: .bottom)
    }

    private func shortDay(_ offset: Int) -> String {
        let labels = ["一", "二", "三", "四", "五", "六", "日"]
        return labels[offset % labels.count]
    }
}

private struct LessonsView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "practice", title: "Calm tools", subtitle: "small steps")
                LessonCard(title: "reframe", subtitle: "notice the thought", tint: SleepPalette.indigo, symbol: "brain.head.profile")
                LessonCard(title: "leave bed", subtitle: "return when sleepy", tint: SleepPalette.green, symbol: "figure.walk.motion")
                LessonCard(title: "breathe", subtitle: "slow the body first", tint: SleepPalette.lavender, symbol: "wind")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

private struct LessonCard: View {
    let title: String
    let subtitle: String
    let tint: Color
    let symbol: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(SleepPalette.night)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SleepPalette.night)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SleepPalette.textSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(18)
        .background(SleepPalette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SettingsView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "settings", title: "Quiet defaults", subtitle: "keep it gentle")
                ToggleCard(title: "bedtime reminder", subtitle: "30 min before")
                ToggleCard(title: "wake reminder", subtitle: "same time daily")
                SleepCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("data")
                            .font(.headline.weight(.bold))
                        SettingsAction(title: "export", tint: SleepPalette.indigo)
                        SettingsAction(title: "reset", tint: SleepPalette.pink)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

private struct ToggleCard: View {
    let title: String
    let subtitle: String
    @State private var enabled = true

    var body: some View {
        SleepCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SleepPalette.night)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(SleepPalette.textSoft)
                }
                Spacer()
                Toggle("", isOn: $enabled)
                    .labelsHidden()
            }
        }
    }
}

private struct SettingsAction: View {
    let title: String
    let tint: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SleepPalette.night)
            Spacer()
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
        }
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct QuickLogSheet: View {
    @Binding var draft: QuickLogDraft
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeader(eyebrow: "log", title: "Last night", subtitle: "keep it light")
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("time")
                                    .font(.headline.weight(.bold))
                                DatePicker("记录日期", selection: $draft.date, displayedComponents: .date)
                                DatePicker("就寝时间", selection: $draft.bedtime, displayedComponents: .hourAndMinute)
                                DatePicker("入睡时间", selection: $draft.sleepStart, displayedComponents: .hourAndMinute)
                                DatePicker("醒来时间", selection: $draft.wakeTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("feeling")
                                    .font(.headline.weight(.bold))
                                Stepper("睡眠质量 \(draft.sleepQuality)/10", value: $draft.sleepQuality, in: 1...10)
                                Stepper("心情 \(draft.moodRating)/10", value: $draft.moodRating, in: 1...10)
                                Stepper("夜间觉醒 \(draft.nightAwakenings) 次", value: $draft.nightAwakenings, in: 0...6)
                            }
                        }
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("notes")
                                    .font(.headline.weight(.bold))
                                Toggle("今天摄入咖啡因", isOn: $draft.caffeineIntake)
                                Stepper("睡前屏幕 \(draft.screenTimeMinutes) 分钟", value: $draft.screenTimeMinutes, in: 0...180, step: 5)
                                TextField("备注", text: Binding(
                                    get: { draft.notes ?? "" },
                                    set: { draft.notes = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                        Button {
                            onSave()
                            dismiss()
                        } label: {
                            Text("save")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SleepPalette.night)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("close") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(SleepPalette.textFaint)
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(SleepPalette.night)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(SleepPalette.textSoft)
        }
    }
}

private struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "moon.stars.fill").foregroundStyle(SleepPalette.night))
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(SleepPalette.night)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(SleepPalette.textSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(SleepPalette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
    }
}

private struct SleepCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(SleepPalette.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    let schema = Schema([SleepDiaryEntry.self, SleepWindow.self, DailyTask.self, CBTISessionConfig.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ContentView()
        .modelContainer(container)
}
