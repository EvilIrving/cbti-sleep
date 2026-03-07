import SwiftUI
import SwiftData
import Charts

// MARK: - Design System

private extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

private enum Theme {
    static let bgPrimary = Color(hex: 0x0B1020)
    static let bgSecondary = Color(hex: 0x121833)
    static let cardBg = Color(hex: 0x1B2345)
    static let cardGradientEnd = Color(hex: 0x232C56)

    static let indigo = Color(hex: 0x6366F1)
    static let amber = Color(hex: 0xF59E0B)
    static let green = Color(hex: 0x34D399)
    static let red = Color(hex: 0xFB7185)

    static let textPrimary = Color(hex: 0xF8FAFC)
    static let textSecondary = Color(hex: 0x94A3B8)
    static let textMuted = Color(hex: 0x64748B)

    static let hPad: CGFloat = 20
    static let cardGap: CGFloat = 16
    static let radius: CGFloat = 24
    static let btnH: CGFloat = 56

    static let largeTitleFont: Font = .system(size: 34, weight: .bold, design: .rounded)
    static let titleFont: Font = .system(size: 24, weight: .bold, design: .rounded)
    static let headlineFont: Font = .system(size: 18, weight: .semibold, design: .rounded)
    static let bodyFont: Font = .system(size: 16, design: .rounded)
    static let captionFont: Font = .system(size: 13, design: .rounded)
    static let sleepTimeFont: Font = .system(size: 48, weight: .semibold, design: .rounded)
}

private struct EffPoint: Identifiable {
    let id = UUID()
    let date: Date
    let eff: Double
}

private struct SleepEntryDraft {
    var bedtime: Date
    var wakeTime: Date
    var latencyMinutes: Int
    var quality: SleepQualityOption
    var awakenings: AwakeningsOption

    var sleepStart: Date {
        bedtime.addingTimeInterval(TimeInterval(latencyMinutes * 60))
    }
}

private enum SleepEditorDestination: Identifiable {
    case checkIn
    case manual
    case edit(SleepDiaryEntry)

    var id: String {
        switch self {
        case .checkIn:
            return "checkIn"
        case .manual:
            return "manual"
        case .edit(let entry):
            return "edit-\(ObjectIdentifier(entry))"
        }
    }

    var title: String {
        switch self {
        case .checkIn:
            return "Morning Check-in"
        case .manual:
            return "Log Sleep"
        case .edit:
            return "Edit Last Night"
        }
    }

    var editingEntry: SleepDiaryEntry? {
        if case .edit(let entry) = self {
            return entry
        }
        return nil
    }
}

// MARK: - Main View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SleepDiaryEntry.date, order: .reverse) private var diaryEntries: [SleepDiaryEntry]
    @Query(sort: \SleepWindow.start, order: .reverse) private var windows: [SleepWindow]
    @Query private var configs: [CBTISessionConfig]

    @State private var selectedTab = 0
    @State private var showBedtimeFlow = false
    @State private var editorDestination: SleepEditorDestination?
    @State private var seeded = false

    @AppStorage("pendingBedtime") private var pendingBedtimeTS: Double = 0
    @AppStorage("targetWakeHour") private var targetWakeHour = 7
    @AppStorage("targetWakeMinute") private var targetWakeMinute = 0
    @AppStorage("lastAdjustWeek") private var lastAdjustWeek = 0
    @AppStorage("lastCantSleepEvent") private var lastCantSleepEventTS: Double = 0

    private var currentWindow: SleepWindow? { windows.first }
    private var efficiency: Double { SleepDataService.efficiency(from: diaryEntries) }

    private var todayEntry: SleepDiaryEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return diaryEntries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var lastEntry: SleepDiaryEntry? {
        todayEntry ?? diaryEntries.first
    }

    private var pendingBedtime: Date? {
        guard pendingBedtimeTS > 0 else { return nil }
        return Date(timeIntervalSince1970: pendingBedtimeTS)
    }

    private var needsCheckIn: Bool {
        todayEntry == nil && Calendar.current.component(.hour, from: Date()) < 14
    }

    private var driftMessage: String? {
        guard let lastEntry else { return nil }
        return SleepDataService.driftMessage(for: lastEntry, plannedWindow: currentWindow)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ZStack {
                    AppBg()
                    ScrollView(.vertical, showsIndicators: false) {
                        HomeContent(
                            entries: diaryEntries,
                            lastEntry: lastEntry,
                            window: currentWindow,
                            efficiency: efficiency,
                            needsCheckIn: needsCheckIn,
                            pendingBedtime: pendingBedtime,
                            driftMessage: driftMessage,
                            onCheckIn: { editorDestination = .checkIn },
                            onEditLastNight: openLastNightEditor,
                            onBedtime: { showBedtimeFlow = true }
                        )
                        .padding(.horizontal, Theme.hPad)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
                .navigationBarHidden(true)
                .task {
                    seedIfNeeded()
                    checkWeeklyAdjust()
                }
            }
            .tabItem { Label("Home", systemImage: "moon.stars.fill") }
            .tag(0)

            NavigationStack {
                ZStack {
                    AppBg()
                    SleepProgressView(entries: diaryEntries)
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
            .tag(1)

            NavigationStack {
                ZStack {
                    AppBg()
                    SleepSettingsView(wakeHour: $targetWakeHour, wakeMinute: $targetWakeMinute)
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(2)
        }
        .tint(Theme.indigo)
        .sheet(item: $editorDestination) { destination in
            SleepEntryFormView(
                title: destination.title,
                plannedWindow: currentWindow,
                initialDraft: draft(for: destination),
                isCheckIn: {
                    if case .checkIn = destination {
                        return true
                    }
                    return false
                }(),
                onSave: { draft in
                    saveSleepEntry(draft, editing: destination.editingEntry)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showBedtimeFlow) {
            BedtimeFlowView(
                onBedtime: { bedtime in
                    pendingBedtimeTS = bedtime.timeIntervalSince1970
                },
                onCantSleep: {
                    lastCantSleepEventTS = Date().timeIntervalSince1970
                }
            )
        }
    }

    // MARK: - Data Operations

    private func seedIfNeeded() {
        guard !seeded else { return }
        if windows.isEmpty {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let wake = Calendar.current.date(
                bySettingHour: targetWakeHour, minute: targetWakeMinute, second: 0, of: tomorrow
            ) ?? tomorrow
            modelContext.insert(SleepWindow(start: wake.addingTimeInterval(-6 * 3600), end: wake))
        }
        if configs.isEmpty {
            modelContext.insert(CBTISessionConfig(startDate: Date(), durationWeeks: 12))
        }
        try? modelContext.save()
        seeded = true
    }

    private func checkWeeklyAdjust() {
        let cal = Calendar.current
        let weekKey = cal.component(.year, from: Date()) * 100 + cal.component(.weekOfYear, from: Date())
        guard weekKey != lastAdjustWeek else { return }

        let recent = Array(diaryEntries.prefix(7))
        guard recent.count >= 5, let current = currentWindow else { return }

        let eff = SleepDataService.efficiency(from: recent)
        let delta: TimeInterval
        if eff > 0.90 {
            delta = 15 * 60
        } else if eff < 0.85 {
            delta = -15 * 60
        } else {
            delta = 0
        }

        if delta != 0 {
            let newDuration = min(max(current.duration + delta, 5 * 3600), 9 * 3600)
            let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let wake = cal.date(
                bySettingHour: targetWakeHour, minute: targetWakeMinute, second: 0, of: tomorrow
            ) ?? tomorrow
            modelContext.insert(SleepWindow(start: wake.addingTimeInterval(-newDuration), end: wake))
            try? modelContext.save()
        }
        lastAdjustWeek = weekKey
    }

    private func openLastNightEditor() {
        if let todayEntry {
            editorDestination = .edit(todayEntry)
        } else if needsCheckIn {
            editorDestination = .checkIn
        } else {
            editorDestination = .manual
        }
    }

    private func draft(for destination: SleepEditorDestination) -> SleepEntryDraft {
        switch destination {
        case .checkIn:
            return SleepEntryDraft(
                bedtime: defaultBedtime(),
                wakeTime: defaultWakeTime(),
                latencyMinutes: pendingBedtime != nil ? 15 : 30,
                quality: .ok,
                awakenings: .zero
            )
        case .manual:
            return SleepEntryDraft(
                bedtime: defaultBedtime(),
                wakeTime: defaultWakeTime(),
                latencyMinutes: 15,
                quality: .ok,
                awakenings: .zero
            )
        case .edit(let entry):
            return SleepEntryDraft(
                bedtime: roundedToQuarterHour(entry.bedtime),
                wakeTime: roundedToQuarterHour(entry.wakeTime ?? defaultWakeTime()),
                latencyMinutes: snappedLatency(entry.sleepLatencyMinutes ?? 15),
                quality: SleepQualityOption(score: entry.sleepQuality),
                awakenings: AwakeningsOption(count: entry.nightAwakenings)
            )
        }
    }

    private func defaultBedtime() -> Date {
        if let pendingBedtime {
            return roundedToQuarterHour(pendingBedtime)
        }

        if let window = currentWindow {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let bedtime = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: window.start),
                minute: Calendar.current.component(.minute, from: window.start),
                second: 0,
                of: yesterday
            ) ?? yesterday.addingTimeInterval(-7 * 3600)
            return roundedToQuarterHour(bedtime)
        }

        return roundedToQuarterHour(Date().addingTimeInterval(-8 * 3600))
    }

    private func defaultWakeTime() -> Date {
        let today = Date()
        let anchored = Calendar.current.date(
            bySettingHour: targetWakeHour,
            minute: targetWakeMinute,
            second: 0,
            of: today
        ) ?? today
        return roundedToQuarterHour(max(anchored, Date()))
    }

    private func saveSleepEntry(_ draft: SleepEntryDraft, editing entry: SleepDiaryEntry?) {
        let bedtime = roundedToQuarterHour(draft.bedtime)
        let wakeTime = roundedToQuarterHour(draft.wakeTime)
        let sleepStart = bedtime.addingTimeInterval(TimeInterval(draft.latencyMinutes * 60))
        let wakeDay = Calendar.current.startOfDay(for: wakeTime)

        if let entry {
            entry.date = wakeDay
            entry.bedtime = bedtime
            entry.sleepStart = sleepStart
            entry.wakeTime = wakeTime
            entry.sleepQuality = draft.quality.numericValue
            entry.nightAwakenings = draft.awakenings.rawValue
            entry.moodRating = draft.quality.numericValue
        } else {
            let newEntry = SleepDiaryEntry(
                date: wakeDay,
                bedtime: bedtime,
                sleepStart: sleepStart,
                wakeTime: wakeTime,
                sleepQuality: draft.quality.numericValue,
                caffeineIntake: false,
                screenTimeMinutes: 0,
                nightAwakenings: draft.awakenings.rawValue,
                moodRating: draft.quality.numericValue
            )
            modelContext.insert(newEntry)
        }

        try? modelContext.save()
        pendingBedtimeTS = 0
        editorDestination = nil
    }
}

// MARK: - Background

private struct AppBg: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.bgPrimary, Theme.bgSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Theme.indigo.opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 100, y: -60)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Theme.indigo.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: -60, y: 60)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Home Screen

private struct HomeContent: View {
    let entries: [SleepDiaryEntry]
    let lastEntry: SleepDiaryEntry?
    let window: SleepWindow?
    let efficiency: Double
    let needsCheckIn: Bool
    let pendingBedtime: Date?
    let driftMessage: String?
    let onCheckIn: () -> Void
    let onEditLastNight: () -> Void
    let onBedtime: () -> Void

    private var adjustment: SleepDataService.WindowAdjustment? {
        SleepDataService.weeklyAdjustment(from: entries, currentWindow: window)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.cardGap) {
            GreetingHeader()

            if needsCheckIn {
                CheckInBanner(onTap: onCheckIn)
            }

            TonightPlanCard(window: window, efficiency: efficiency)

            if let pendingBedtime, lastEntry?.date != Calendar.current.startOfDay(for: Date()) {
                PendingBedtimeCard(pendingBedtime: pendingBedtime)
            }

            ActionRow(
                needsCheckIn: needsCheckIn,
                onEditLastNight: onEditLastNight,
                onBedtime: onBedtime
            )

            if let lastEntry {
                ActualSleepCard(entry: lastEntry, onEdit: onEditLastNight)
            } else {
                EmptyActualSleepCard(onLog: onEditLastNight)
            }

            if let driftMessage {
                GuidanceCard(message: driftMessage, color: Theme.amber, icon: "lightbulb.max")
            }

            CoachCard(
                message: SleepDataService.coachMessage(efficiency: efficiency, entryCount: entries.count)
            )

            if let adj = adjustment, adj.minutes != 0 {
                AdjustmentCard(adjustment: adj)
            }
        }
    }
}

private struct GreetingHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                Text("Sleep")
                    .font(Theme.largeTitleFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(Theme.indigo)
                .frame(width: 44, height: 44)
                .background(Theme.indigo.opacity(0.15), in: Circle())
        }
        .padding(.top, 10)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good Morning" }
        if h < 18 { return "Good Afternoon" }
        return "Good Evening"
    }
}

private struct TonightPlanCard: View {
    let window: SleepWindow?
    let efficiency: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TONIGHT'S PLAN")
                        .font(Theme.captionFont.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1.2)
                    Text("This is your training window, not your log.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                EffBadge(value: efficiency)
            }

            VStack(spacing: 6) {
                Text(fmt(window?.start))
                    .font(Theme.sleepTimeFont)
                    .foregroundStyle(Theme.textPrimary)
                Image(systemName: "arrow.down")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textMuted)
                Text(fmt(window?.end))
                    .font(Theme.sleepTimeFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Text("If the night goes differently, edit the actual log tomorrow. The plan and the log are separate.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Theme.cardBg, Theme.cardGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func fmt(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        return timeFormatter.string(from: date)
    }
}

private struct PendingBedtimeCard: View {
    let pendingBedtime: Date

    var body: some View {
        GuidanceCard(
            message: "Bedtime started at \(dateTimeFormatter.string(from: pendingBedtime)). Finish the morning check-in after you wake up, then correct anything that happened differently.",
            color: Theme.indigo,
            icon: "bed.double.fill"
        )
    }
}

private struct EffBadge: View {
    let value: Double

    private var color: Color {
        if value >= 0.90 { return Theme.green }
        if value >= 0.85 { return Theme.amber }
        return Theme.indigo
    }

    var body: some View {
        Text("\(Int(value * 100))%")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
    }
}

private struct CheckInBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.amber)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Check-in")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Record what actually happened last night")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(18)
            .background(
                Theme.amber.opacity(0.10),
                in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(Theme.amber.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

private struct ActionRow: View {
    let needsCheckIn: Bool
    let onEditLastNight: () -> Void
    let onBedtime: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEditLastNight) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(needsCheckIn ? "Log Last Night" : "Edit Last Night")
                        .font(Theme.headlineFont)
                    Text("Fix actual times")
                        .font(Theme.captionFont)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Theme.btnH)
                .padding(.horizontal, 18)
                .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .foregroundStyle(Theme.textPrimary)

            Button(action: onBedtime) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("I'm Going To Bed")
                        .font(Theme.headlineFont)
                    Text("Start bedtime mode")
                        .font(Theme.captionFont)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Theme.btnH)
                .padding(.horizontal, 18)
                .background(Theme.indigo, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .foregroundStyle(.white)
        }
    }
}

private struct ActualSleepCard: View {
    let entry: SleepDiaryEntry
    let onEdit: () -> Void

    var body: some View {
        CBTICard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Night")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Actual sleep log")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button("Edit") {
                        onEdit()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.indigo)
                }

                HStack(spacing: 12) {
                    MetricItem(label: "Bedtime", value: entry.formattedBedtime)
                    MetricItem(label: "Sleep", value: entry.formattedSleepStart)
                    MetricItem(label: "Wake", value: entry.formattedWakeTime)
                }

                HStack(spacing: 12) {
                    MetricItem(label: "Latency", value: latencyText)
                    MetricItem(label: "Duration", value: entry.formattedDuration)
                    MetricItem(label: "Quality", value: "\(entry.sleepQuality)/10")
                }
            }
        }
    }

    private var latencyText: String {
        guard let latency = entry.sleepLatencyMinutes else { return "--" }
        return "\(latency)m"
    }
}

private struct EmptyActualSleepCard: View {
    let onLog: () -> Void

    var body: some View {
        CBTICard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Last Night")
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)
                Text("No actual sleep log yet. Record what really happened so CBTI can adjust from real data, not guesses.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Log Sleep") {
                    onLog()
                }
                .font(Theme.headlineFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.btnH)
                .background(Theme.indigo, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct MetricItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textMuted)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GuidanceCard: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        CBTICard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(
                        color.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                Text(message)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CoachCard: View {
    let message: String

    var body: some View {
        CBTICard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Theme.indigo)
                    .frame(width: 40, height: 40)
                    .background(
                        Theme.indigo.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text("CBTI Coach")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.textPrimary)
                    Text(message)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct AdjustmentCard: View {
    let adjustment: SleepDataService.WindowAdjustment

    var body: some View {
        CBTICard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Theme.green)
                    Text("Weekly Adjustment")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.textPrimary)
                }
                Text(adjustment.message)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Sleep Entry Form

private struct SleepEntryFormView: View {
    let title: String
    let plannedWindow: SleepWindow?
    let isCheckIn: Bool
    let onSave: (SleepEntryDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: SleepEntryDraft

    init(
        title: String,
        plannedWindow: SleepWindow?,
        initialDraft: SleepEntryDraft,
        isCheckIn: Bool,
        onSave: @escaping (SleepEntryDraft) -> Void
    ) {
        self.title = title
        self.plannedWindow = plannedWindow
        self.isCheckIn = isCheckIn
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    private let latencyOptions = Array(stride(from: 0, through: 240, by: 15))

    private var validationMessage: String? {
        if draft.wakeTime <= draft.bedtime {
            return "Wake time needs to be after bedtime."
        }
        if draft.wakeTime <= draft.sleepStart {
            return "Wake time needs to be after falling asleep."
        }
        return nil
    }

    private var bedtimeBinding: Binding<Date> {
        Binding(
            get: { draft.bedtime },
            set: { draft.bedtime = roundedToQuarterHour($0) }
        )
    }

    private var wakeTimeBinding: Binding<Date> {
        Binding(
            get: { draft.wakeTime },
            set: { draft.wakeTime = roundedToQuarterHour($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let plannedWindow {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tonight's Plan")
                                .font(Theme.headlineFont)
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(timeFormatter.string(from: plannedWindow.start)) - \(timeFormatter.string(from: plannedWindow.end))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("This plan trains consistency. The fields below should reflect what actually happened.")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.cardBg)
                }

                Section {
                    DatePicker(
                        "Bed time",
                        selection: bedtimeBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Theme.indigo)

                    Picker("Sleep latency", selection: $draft.latencyMinutes) {
                        ForEach(latencyOptions, id: \.self) { value in
                            Text("\(value) min").tag(value)
                        }
                    }

                    DatePicker(
                        "Wake time",
                        selection: wakeTimeBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Theme.indigo)
                } header: {
                    Text("Actual Sleep")
                } footer: {
                    Text("Times snap to 15-minute steps so correction stays quick.")
                }
                .listRowBackground(Theme.cardBg)

                Section {
                    Picker("Sleep quality", selection: $draft.quality) {
                        ForEach(SleepQualityOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Awakenings", selection: $draft.awakenings) {
                        ForEach(AwakeningsOption.allCases, id: \.self) { option in
                            Text(option.displayText).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Subjective Check-in")
                }
                .listRowBackground(Theme.cardBg)

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Estimated sleep time")
                            Spacer()
                            Text(timeFormatter.string(from: draft.sleepStart))
                        }
                        HStack {
                            Text("Estimated duration")
                            Spacer()
                            Text(durationFormatter(draft.wakeTime.timeIntervalSince(draft.sleepStart)))
                        }
                    }
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                } header: {
                    Text("Derived From Actual Log")
                }
                .listRowBackground(Theme.cardBg)

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.red)
                    }
                    .listRowBackground(Theme.cardBg)
                } else if isCheckIn {
                    Section {
                        Text("If you did not follow the plan exactly, edit the actual times here anyway. CBTI works best with real behavior.")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .listRowBackground(Theme.cardBg)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBg())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(validationMessage != nil)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Bedtime Flow

private struct BedtimeFlowView: View {
    let onBedtime: (Date) -> Void
    let onCantSleep: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sleeping = false

    var body: some View {
        ZStack {
            AppBg()
            if sleeping {
                SleepModeScreen(
                    onCantSleep: onCantSleep,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity)
            } else {
                RoutineScreen(
                    onSleep: {
                        onBedtime(Date())
                        withAnimation(.easeInOut(duration: 0.8)) {
                            sleeping = true
                        }
                    },
                    onClose: { dismiss() }
                )
            }
        }
        .animation(.easeInOut, value: sleeping)
    }
}

private struct RoutineScreen: View {
    let onSleep: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.cardBg, in: Circle())
                }
            }
            .padding(.horizontal, Theme.hPad)
            .padding(.top, 16)

            Spacer()

            Text("Bedtime Routine")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 12)

            Text("Tap when you actually get into bed. You can correct tomorrow if the night changes.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

            VStack(spacing: 14) {
                routineRow(icon: "lightbulb.slash", text: "Dim the lights")
                routineRow(icon: "iphone.slash", text: "Put away your phone")
                routineRow(icon: "wind", text: "Deep breathing")
            }
            .padding(.horizontal, Theme.hPad)

            Spacer()

            Button(action: onSleep) {
                Text("I'm Going To Bed")
                    .font(Theme.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.btnH)
                    .background(Theme.indigo, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
            .padding(.horizontal, Theme.hPad)
            .padding(.bottom, 50)
        }
    }

    @ViewBuilder
    private func routineRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.amber)
                .frame(width: 44, height: 44)
                .background(
                    Theme.amber.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
    }
}

private struct SleepModeScreen: View {
    let onCantSleep: () -> Void
    let onDismiss: () -> Void

    @State private var showGuidance = false

    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "moon.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.indigo.opacity(0.5))
                .padding(.bottom, 20)
            Text("Good Night")
                .font(Theme.largeTitleFont)
                .foregroundStyle(Theme.textPrimary.opacity(0.8))
            Text("If you cannot fall asleep after a while, use the guidance below.")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onCantSleep()
                showGuidance = true
            } label: {
                Text("I Can't Sleep")
                    .font(Theme.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.btnH)
                    .background(Theme.amber, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
            .padding(.horizontal, Theme.hPad)

            Button(action: onDismiss) {
                Text("Dismiss")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 16)
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showGuidance) {
            CantSleepGuidanceView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct CantSleepGuidanceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Stimulus Control") {
                    Label("Get out of bed", systemImage: "figure.walk")
                    Label("Try a quiet activity", systemImage: "book.closed")
                    Label("Return when sleepy", systemImage: "moon.zzz.fill")
                }

                Section {
                    Text("A rough night does not mean the plan failed. Keep the wake-up time stable and log what actually happened in the morning.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("I Can't Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Progress Screen

private struct SleepProgressView: View {
    let entries: [SleepDiaryEntry]

    private var recent14: [SleepDiaryEntry] { Array(entries.prefix(14)) }
    private var avgEff: Double { SleepDataService.efficiency(from: recent14) }
    private var avgSleep: TimeInterval { SleepDataService.averageSleepTime(from: recent14) }
    private var avgWakes: Double { SleepDataService.averageAwakenings(from: recent14) }

    private var chartData: [EffPoint] {
        recent14.reversed().compactMap { entry in
            guard let eff = entry.sleepEfficiency else { return nil }
            return EffPoint(date: entry.date, eff: eff * 100)
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.cardGap) {
                Text("Progress")
                    .font(Theme.largeTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)

                CBTICard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sleep Efficiency — 14 Days")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)

                        if chartData.count >= 2 {
                            Chart(chartData) { point in
                                LineMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Efficiency", point.eff)
                                )
                                .foregroundStyle(Theme.indigo)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))

                                AreaMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Efficiency", point.eff)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [Theme.indigo.opacity(0.25), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value("Efficiency", point.eff)
                                )
                                .foregroundStyle(Theme.indigo)
                                .symbolSize(30)
                            }
                            .chartYScale(domain: 40...100)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 3)) {
                                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: [50, 70, 90]) {
                                    AxisValueLabel()
                                        .foregroundStyle(Theme.textMuted)
                                    AxisGridLine()
                                        .foregroundStyle(Theme.textMuted.opacity(0.15))
                                }
                            }
                            .frame(height: 200)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.largeTitle)
                                    .foregroundStyle(Theme.textMuted)
                                Text("Need at least 2 actual logs to show trends")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                HStack(spacing: 12) {
                    StatCard(label: "Avg Efficiency", value: "\(Int(avgEff * 100))%", color: Theme.indigo)
                    StatCard(label: "Avg Sleep", value: durationFormatter(avgSleep), color: Theme.green)
                    StatCard(label: "Awakenings", value: String(format: "%.1f", avgWakes), color: Theme.amber)
                }
            }
            .padding(.horizontal, Theme.hPad)
            .padding(.bottom, 100)
        }
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - Settings Screen

private struct SleepSettingsView: View {
    @Binding var wakeHour: Int
    @Binding var wakeMinute: Int
    @State private var bedtimeReminder = true
    @State private var morningReminder = true

    private var wakeDate: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: wakeHour,
                    minute: wakeMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: {
                let rounded = roundedToQuarterHour($0)
                wakeHour = Calendar.current.component(.hour, from: rounded)
                wakeMinute = Calendar.current.component(.minute, from: rounded)
            }
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.cardGap) {
                Text("Settings")
                    .font(Theme.largeTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)

                CBTICard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Notifications")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)

                        Toggle(isOn: $bedtimeReminder) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bedtime Reminder")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("30 min before the planned bedtime")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .tint(Theme.indigo)

                        Toggle(isOn: $morningReminder) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Morning Check-in")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Prompt after the planned wake time")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .tint(Theme.indigo)
                    }
                }

                CBTICard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sleep Plan")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)
                        DatePicker(
                            "Target Wake Time",
                            selection: wakeDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .tint(Theme.indigo)
                        .foregroundStyle(Theme.textPrimary)

                        Text("This changes the CBTI plan anchor. Actual sleep logs are edited separately on Home.")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                CBTICard {
                    Button {
                        // TODO: export implementation
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Data Export")
                                    .font(Theme.headlineFont)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Export actual sleep logs as CSV")
                                    .font(Theme.captionFont)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Theme.indigo)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.hPad)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Shared Components

private struct CBTICard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Helpers

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private func roundedToQuarterHour(_ date: Date) -> Date {
    let interval = 15.0 * 60.0
    let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded() * interval
    return Date(timeIntervalSinceReferenceDate: rounded)
}

private func snappedLatency(_ minutes: Int) -> Int {
    let step = 15
    return max(0, Int((Double(minutes) / Double(step)).rounded()) * step)
}

private func durationFormatter(_ interval: TimeInterval) -> String {
    guard interval > 0 else { return "--" }
    let hours = Int(interval) / 3600
    let minutes = Int(interval) / 60 % 60
    return "\(hours)h \(minutes)m"
}

// MARK: - Preview

#Preview {
    let schema = Schema([SleepDiaryEntry.self, SleepWindow.self, DailyTask.self, CBTISessionConfig.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ContentView()
        .modelContainer(container)
}
