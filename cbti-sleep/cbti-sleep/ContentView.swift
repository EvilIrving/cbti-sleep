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
    static let background = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let card = Color.white.opacity(0.92)
    static let night = Color(red: 0.11, green: 0.15, blue: 0.30)
    static let indigo = Color(red: 0.41, green: 0.44, blue: 0.91)
    static let lavender = Color(red: 0.86, green: 0.88, blue: 1.00)
    static let yellow = Color(red: 0.96, green: 0.84, blue: 0.28)
    static let green = Color(red: 0.34, green: 0.73, blue: 0.49)
    static let pink = Color(red: 0.94, green: 0.72, blue: 0.84)
    static let textSoft = Color(red: 0.43, green: 0.46, blue: 0.56)
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
            colors: [SleepPalette.background, Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(SleepPalette.lavender.opacity(0.55))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: 90, y: -60)
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
                Text("今晚继续把睡眠拉回正轨")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SleepPalette.night)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
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
                    Text("今夜睡眠窗口")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(windowText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("固定起床时间比“早点睡”更重要")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer()
                VStack(spacing: 10) {
                    GlowOrb()
                    Text("\(Int(completionRate * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            HStack(spacing: 10) {
                HeroPill(title: "连续", value: "\(streak) 天")
                HeroPill(title: "建议时长", value: durationText)
                HeroPill(title: "起床", value: wakeText)
            }
        }
        .padding(22)
        .background(
            LinearGradient(colors: [SleepPalette.night, SleepPalette.indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: SleepPalette.indigo.opacity(0.28), radius: 24, y: 16)
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
                .fill(.white.opacity(0.16))
                .frame(width: 82, height: 82)
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 58, height: 58)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.68))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct InsightStrip: View {
    let efficiency: Double
    let streak: Int
    let entryCount: Int

    var body: some View {
        HStack(spacing: 12) {
            MiniStatCard(title: "睡眠效率", value: "\(Int(efficiency * 100))%", tint: SleepPalette.yellow, symbol: "bolt.fill")
            MiniStatCard(title: "连胜记录", value: "\(streak) 天", tint: SleepPalette.green, symbol: "flame.fill")
            MiniStatCard(title: "已记录", value: "\(entryCount)", tint: SleepPalette.pink, symbol: "calendar")
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
                .font(.headline)
                .foregroundStyle(SleepPalette.night)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
    }
}

private struct FocusTaskCard: View {
    let task: DailyTask
    let completionRate: Double
    let toggleTask: (DailyTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("今日首要任务")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(Int(completionRate * 100))% 完成")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SleepPalette.night)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.8), in: Capsule())
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SleepPalette.night)
                    Text(task.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(SleepPalette.night.opacity(0.74))
                }
                Spacer()
                BlobFace(color: SleepPalette.green, mood: task.isCompleted ? "face.smiling.fill" : "face.dashed.fill")
            }
            Button {
                toggleTask(task)
            } label: {
                Text(task.isCompleted ? "已完成，继续保持" : "标记完成")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(task.isCompleted ? SleepPalette.night : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(task.isCompleted ? Color.white.opacity(0.76) : SleepPalette.night, in: Capsule())
            }
        }
        .padding(22)
        .background(SleepPalette.yellow, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: SleepPalette.yellow.opacity(0.25), radius: 16, y: 10)
    }
}

private struct BlobFace: View {
    let color: Color
    let mood: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color)
                .frame(width: 92, height: 92)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white, lineWidth: 6))
            Image(systemName: mood)
                .font(.system(size: 34))
                .foregroundStyle(SleepPalette.night)
        }
        .rotationEffect(.degrees(-8))
    }
}

private struct WeekProgressCard: View {
    let tasks: [DailyTask]

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("本周进展")
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
                                    .fill(done ? SleepPalette.night : Color.black.opacity(0.06))
                                    .frame(width: 34, height: 34)
                                if done {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
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
                    Text("睡眠计划")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(SleepPalette.indigo)
                }
                HStack(spacing: 14) {
                    PlanMetric(title: "就寝", value: timeText(start))
                    PlanMetric(title: "起床", value: timeText(end))
                    PlanMetric(title: "时长", value: durationText)
                }
                Text("建议在睡意明显时再上床，不要为了“早点睡”提前躺平。")
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
        .background(SleepPalette.lavender.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct QuickCaptureCard: View {
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("快速记录")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SleepPalette.night)
                    Text("像参考 app 那样，把主操作做成明确 CTA，而不是埋在表单里。")
                        .font(.subheadline)
                        .foregroundStyle(SleepPalette.night.opacity(0.72))
                }
                Spacer()
                BlobFace(color: SleepPalette.pink, mood: "sparkles")
            }
            Button {
                onTap()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("记录昨晚睡眠")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(SleepPalette.night, in: Capsule())
            }
        }
        .padding(22)
        .background(SleepPalette.green, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: SleepPalette.green.opacity(0.2), radius: 16, y: 10)
    }
}

private struct RecordsOverview: View {
    let entries: [SleepDiaryEntry]

    var body: some View {
        SleepCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("最近记录")
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
                            Text("睡眠时长 \(recent.formattedDuration)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(SleepPalette.night)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("主观感受")
                                .font(.caption)
                                .foregroundStyle(SleepPalette.textSoft)
                            Text("\(recent.sleepQuality)/10")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(SleepPalette.indigo)
                        }
                    }
                } else {
                    Text("今晚开始第一条记录，让数据先流动起来。")
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
                SectionHeader(eyebrow: "睡眠日记", title: "昨晚发生了什么", subtitle: "保留连续记录，才能让 CBTI 的建议更可信。")
                Button {
                    addAction()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("新增一条记录")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(
                        LinearGradient(colors: [SleepPalette.night, SleepPalette.indigo], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                }
                ForEach(entries) { entry in
                    DiaryEntryCard(entry: entry)
                }
                if entries.isEmpty {
                    EmptyStateCard(title: "还没有睡眠日记", subtitle: "先从今天开始。一次 30 秒记录，比空白更有价值。", tint: SleepPalette.lavender)
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
                        Text("入睡 \(timeText(entry.sleepStart))  ·  醒来 \(timeText(entry.wakeTime))")
                            .font(.subheadline)
                            .foregroundStyle(SleepPalette.textSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(entry.formattedDuration)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(SleepPalette.night)
                        Text("质量 \(entry.sleepQuality)/10")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SleepPalette.indigo)
                    }
                }
                HStack(spacing: 10) {
                    DiaryTag(text: "\(entry.nightAwakenings) 次觉醒", tint: SleepPalette.yellow)
                    DiaryTag(text: "屏幕 \(entry.screenTimeMinutes) 分钟", tint: SleepPalette.green)
                    if entry.caffeineIntake {
                        DiaryTag(text: "咖啡因", tint: SleepPalette.pink)
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
                SectionHeader(eyebrow: "疗程分析", title: "进度要可见，但不要制造焦虑", subtitle: "用温和的图表看趋势，不用生硬 KPI 压你。")
                SleepCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("近 7 次睡眠质量")
                                .font(.headline.weight(.bold))
                            Spacer()
                            Text("本周")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(SleepPalette.night, in: Capsule())
                        }
                        TrendBars(entries: Array(entries.prefix(7).reversed()))
                    }
                }
                HStack(spacing: 12) {
                    MiniStatCard(title: "完成率", value: "\(Int(SleepDataService.completionRate(for: tasks) * 100))%", tint: SleepPalette.yellow, symbol: "checkmark.seal.fill")
                    MiniStatCard(title: "效率", value: "\(Int(SleepDataService.efficiency(from: entries) * 100))%", tint: SleepPalette.green, symbol: "bed.double.fill")
                }
                SleepCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("下一步建议")
                            .font(.headline.weight(.bold))
                        Text("如果连续 7-14 天效率高于 85%，可以再把睡眠窗口温和放宽 15 分钟。")
                            .font(.subheadline)
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
                SectionHeader(eyebrow: "CBTI 工具箱", title: "把内容做成卡片，不要做成说明书", subtitle: "每一项都该能马上行动，而不是只读一遍。")
                LessonCard(title: "认知重构", subtitle: "识别“今晚又要完蛋”的自动化想法，并用证据松动它。", tint: SleepPalette.yellow, symbol: "brain.head.profile")
                LessonCard(title: "刺激控制", subtitle: "只在困倦时上床。超过 20 分钟仍清醒，离开卧室，等睡意回来。", tint: SleepPalette.green, symbol: "figure.walk.motion")
                LessonCard(title: "放松训练", subtitle: "先做 4-7-8 呼吸，再进入身体扫描，让身体先慢下来。", tint: SleepPalette.pink, symbol: "wind")
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
                .background(tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .shadow(color: .black.opacity(0.05), radius: 14, y: 8)
    }
}

private struct SettingsView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(eyebrow: "偏好设置", title: "让提醒更像陪伴，不像催命", subtitle: "文案、频率和导出都要轻一点。")
                ToggleCard(title: "睡前提醒", subtitle: "入睡窗口前 30 分钟轻提醒")
                ToggleCard(title: "起床打卡", subtitle: "固定起床时间提醒")
                SleepCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("数据管理")
                            .font(.headline.weight(.bold))
                        SettingsAction(title: "导出睡眠日记", tint: SleepPalette.lavender)
                        SettingsAction(title: "重置本地数据", tint: SleepPalette.pink)
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
        .background(tint.opacity(0.25), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                        SectionHeader(eyebrow: "睡眠记录", title: "用最短路径记录昨晚", subtitle: "减少表单感，把常用字段放到前面。")
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("时间")
                                    .font(.headline.weight(.bold))
                                DatePicker("记录日期", selection: $draft.date, displayedComponents: .date)
                                DatePicker("就寝时间", selection: $draft.bedtime, displayedComponents: .hourAndMinute)
                                DatePicker("入睡时间", selection: $draft.sleepStart, displayedComponents: .hourAndMinute)
                                DatePicker("醒来时间", selection: $draft.wakeTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("主观感受")
                                    .font(.headline.weight(.bold))
                                Stepper("睡眠质量 \(draft.sleepQuality)/10", value: $draft.sleepQuality, in: 1...10)
                                Stepper("心情 \(draft.moodRating)/10", value: $draft.moodRating, in: 1...10)
                                Stepper("夜间觉醒 \(draft.nightAwakenings) 次", value: $draft.nightAwakenings, in: 0...6)
                            }
                        }
                        SleepCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("行为线索")
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
                            Text("保存这条记录")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(SleepPalette.night, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
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
                .foregroundStyle(SleepPalette.textSoft)
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(SleepPalette.night)
            Text(subtitle)
                .font(.subheadline)
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
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 18, y: 10)
    }
}

#Preview {
    let schema = Schema([SleepDiaryEntry.self, SleepWindow.self, DailyTask.self, CBTISessionConfig.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ContentView()
        .modelContainer(container)
}
