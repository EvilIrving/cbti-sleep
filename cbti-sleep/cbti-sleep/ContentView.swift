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

enum Theme {
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
    case createLastNight
    case edit(SleepDiaryEntry)

    var id: String {
        switch self {
        case .createLastNight:
            return "createLastNight"
        case .edit(let entry):
            return "edit-\(ObjectIdentifier(entry))"
        }
    }

    var title: String {
        switch self {
        case .createLastNight:
            return "Record Last Night"
        case .edit:
            return "Edit Sleep Log"
        }
    }

    var editingEntry: SleepDiaryEntry? {
        if case .edit(let entry) = self {
            return entry
        }
        return nil
    }

    var isNewEntry: Bool {
        if case .createLastNight = self {
            return true
        }
        return false
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
    @AppStorage("targetWakeHour") private var targetWakeHour = 8
    @AppStorage("targetWakeMinute") private var targetWakeMinute = 0
    @AppStorage("lastAdjustWeek") private var lastAdjustWeek = 0
    @AppStorage("lastCantSleepEvent") private var lastCantSleepEventTS: Double = 0

    private var currentWindow: SleepWindow? { windows.first }
    private var efficiency: Double { SleepDataService.efficiency(from: diaryEntries) }

    private var todayEntry: SleepDiaryEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return diaryEntries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var pendingBedtime: Date? {
        guard pendingBedtimeTS > 0 else { return nil }
        return Date(timeIntervalSince1970: pendingBedtimeTS)
    }

    private var needsCheckIn: Bool {
        todayEntry == nil && Calendar.current.component(.hour, from: Date()) < 14
    }

    private var driftMessage: String? {
        guard let todayEntry else { return nil }
        return SleepDataService.driftMessage(for: todayEntry, plannedWindow: currentWindow)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ZStack {
                    AppBg()
                    ScrollView(.vertical, showsIndicators: false) {
                        HomeContent(
                            entries: diaryEntries,
                            todayEntry: todayEntry,
                            window: currentWindow,
                            efficiency: efficiency,
                            needsCheckIn: needsCheckIn,
                            pendingBedtime: pendingBedtime,
                            driftMessage: driftMessage,
                            onCreateLastNight: { editorDestination = .createLastNight },
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
                    SleepHistoryView(
                        entries: diaryEntries,
                        onEdit: { entry in
                            editorDestination = .edit(entry)
                        }
                    )
                }
                .navigationBarHidden(true)
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
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
                isNewEntry: destination.isNewEntry,
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
//        if enableMockSleepSeedData, diaryEntries.isEmpty {
//            seedMockSleepEntries()
//            lastAdjustWeek = currentWeekKey()
//        }
        if windows.isEmpty {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let requestedWake = Calendar.current.date(
                bySettingHour: targetWakeHour, minute: targetWakeMinute, second: 0, of: tomorrow
            ) ?? tomorrow
            let wake = clampedTargetWakeDate(requestedWake)
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
        let weekKey = currentWeekKey()
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
            let requestedWake = cal.date(
                bySettingHour: targetWakeHour, minute: targetWakeMinute, second: 0, of: tomorrow
            ) ?? tomorrow
            let wake = clampedTargetWakeDate(requestedWake)
            modelContext.insert(SleepWindow(start: wake.addingTimeInterval(-newDuration), end: wake))
            try? modelContext.save()
        }
        lastAdjustWeek = weekKey
    }

    private func seedMockSleepEntries() {
        for (daysBack, sample) in mockSleepSeedEntries.enumerated() {
            let wakeDay = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
            )
            let bedtimeBase = mockBedtimeBaseDate(for: sample, wakeDay: wakeDay)
            let bedtime = Calendar.current.date(
                bySettingHour: sample.bedtimeHour,
                minute: sample.bedtimeMinute,
                second: 0,
                of: bedtimeBase
            ) ?? bedtimeBase
            let wakeTime = Calendar.current.date(
                bySettingHour: sample.wakeHour,
                minute: sample.wakeMinute,
                second: 0,
                of: wakeDay
            ) ?? wakeDay
            let sleepStart = bedtime.addingTimeInterval(TimeInterval(sample.latencyMinutes * 60))
            modelContext.insert(
                SleepDiaryEntry(
                    date: wakeDay,
                    bedtime: bedtime,
                    sleepStart: sleepStart,
                    wakeTime: wakeTime,
                    sleepQuality: sample.quality,
                    caffeineIntake: sample.caffeineIntake,
                    screenTimeMinutes: sample.screenTimeMinutes,
                    nightAwakenings: sample.awakenings,
                    moodRating: sample.quality
                )
            )
        }
    }

    private func draft(for destination: SleepEditorDestination) -> SleepEntryDraft {
        switch destination {
        case .createLastNight:
            return SleepEntryDraft(
                bedtime: defaultBedtime(),
                wakeTime: defaultWakeTime(),
                latencyMinutes: pendingBedtime != nil ? 15 : 30,
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
        let requestedWake = Calendar.current.date(
            bySettingHour: targetWakeHour,
            minute: targetWakeMinute,
            second: 0,
            of: today
        ) ?? today
        let anchored = clampedTargetWakeDate(requestedWake)
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
    let todayEntry: SleepDiaryEntry?
    let window: SleepWindow?
    let efficiency: Double
    let needsCheckIn: Bool
    let pendingBedtime: Date?
    let driftMessage: String?
    let onCreateLastNight: () -> Void
    let onBedtime: () -> Void

    private var adjustment: SleepDataService.WindowAdjustment? {
        SleepDataService.weeklyAdjustment(from: entries, currentWindow: window)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.cardGap) {
            GreetingHeader()

            if needsCheckIn {
                CheckInBanner(onTap: onCreateLastNight)
            }

            TonightPlanCard(window: window, efficiency: efficiency)

            if let pendingBedtime, todayEntry == nil {
                PendingBedtimeCard(pendingBedtime: pendingBedtime)
            }

            ActionRow(
                showCreateLastNight: todayEntry == nil && !needsCheckIn,
                onCreateLastNight: onCreateLastNight,
                onBedtime: onBedtime
            )

            if let todayEntry {
                ActualSleepCard(entry: todayEntry)
            }

            if let driftMessage {
                GuidanceCard(message: driftMessage, color: Theme.amber, icon: "lightbulb.max")
            } else if !entries.isEmpty {
                CoachCard(
                    message: SleepDataService.coachMessage(efficiency: efficiency, entryCount: entries.count)
                )
            }

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
    private let compactTimeFont: Font = .system(size: 38, weight: .semibold, design: .rounded)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TONIGHT'S PLAN")
                        .font(Theme.captionFont.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1.2)
                    Text("Training window")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                EffBadge(value: efficiency)
            }

            HStack(alignment: .center, spacing: 12) {
                Text(fmt(window?.start))
                    .font(compactTimeFont)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textMuted)
                Text(fmt(window?.end))
                    .font(compactTimeFont)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            Text("Plan vs actual are separate.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(18)
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
            message: "Bedtime started at \(dateTimeFormatter.string(from: pendingBedtime)). Log the rest in the morning.",
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
                    Text("Record last night's sleep.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("Open")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.amber)
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
        .buttonStyle(.plain)
    }
}

private struct ActionRow: View {
    let showCreateLastNight: Bool
    let onCreateLastNight: () -> Void
    let onBedtime: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showCreateLastNight {
                Button(action: onCreateLastNight) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Record Last Night")
                            .font(Theme.headlineFont)
                        Text("Create sleep log")
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
            }

            Button(action: onBedtime) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("I'm Going To Bed")
                        .font(Theme.headlineFont)
                    Text("Start bedtime")
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

    var body: some View {
        CBTICard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Night")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Recorded sleep")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
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
    let isNewEntry: Bool
    let onSave: (SleepEntryDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: SleepEntryDraft

    init(
        title: String,
        plannedWindow: SleepWindow?,
        initialDraft: SleepEntryDraft,
        isNewEntry: Bool,
        onSave: @escaping (SleepEntryDraft) -> Void
    ) {
        self.title = title
        self.plannedWindow = plannedWindow
        self.isNewEntry = isNewEntry
        self.onSave = onSave
        let normalized = normalizedSleepRange(bedtime: initialDraft.bedtime, wakeTime: initialDraft.wakeTime)
        _draft = State(initialValue: SleepEntryDraft(
            bedtime: normalized.bedtime,
            wakeTime: normalized.wakeTime,
            latencyMinutes: initialDraft.latencyMinutes,
            quality: initialDraft.quality,
            awakenings: initialDraft.awakenings
        ))
    }

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
            set: { updateDraftTimes(bedtime: $0, wakeTime: draft.wakeTime) }
        )
    }

    private var wakeTimeBinding: Binding<Date> {
        Binding(
            get: { draft.wakeTime },
            set: { updateDraftTimes(bedtime: draft.bedtime, wakeTime: $0) }
        )
    }

    private var latencyOptionBinding: Binding<FallAsleepOption> {
        Binding(
            get: { FallAsleepOption(minutes: draft.latencyMinutes) },
            set: { draft.latencyMinutes = $0.midpointMinutes }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBg()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Theme.cardGap) {
                        if let plannedWindow {
                            CBTICard {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Tonight's Plan")
                                            .font(Theme.headlineFont)
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(timeFormatter.string(from: plannedWindow.start)) - \(timeFormatter.string(from: plannedWindow.end))")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("This plan trains consistency. Log what actually happened.")
                                            .font(Theme.captionFont)
                                            .foregroundStyle(Theme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    TimeOffsetChipsView(
                                        title: "Planned bedtime",
                                        baseTimeText: timeFormatter.string(from: plannedWindow.start),
                                        offsets: [15, 30, 60, 120]
                                    ) { offset in
                                        applyPlannedBedtimeOffset(offset)
                                    }
                                }
                            }
                        }

                        CBTICard {
                            VStack(alignment: .leading, spacing: 18) {
                                SleepRangeTimelineView(
                                    title: "Actual Sleep",
                                    subtitle: "Drag bedtime and wake time. Saved automatically.",
                                    startDate: bedtimeBinding,
                                    endDate: wakeTimeBinding
                                )
                            }
                        }

                        CBTICard {
                            VStack(alignment: .leading, spacing: 18) {
                                SelectionChipGroup(
                                    title: "Sleep latency",
                                    options: FallAsleepOption.allCases,
                                    selection: latencyOptionBinding
                                ) { option in
                                    option.rawValue
                                }

                                SelectionChipGroup(
                                    title: "Sleep quality",
                                    options: SleepQualityOption.allCases,
                                    selection: $draft.quality
                                ) { option in
                                    option.rawValue
                                }

                                SelectionChipGroup(
                                    title: "Awakenings",
                                    options: AwakeningsOption.allCases,
                                    selection: $draft.awakenings
                                ) { option in
                                    option.displayText
                                }
                            }
                        }

                        CBTICard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("From This Log")
                                    .font(Theme.headlineFont)
                                    .foregroundStyle(Theme.textPrimary)

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
                        }

                        if let validationMessage {
                            CBTICard {
                                Text(validationMessage)
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else if isNewEntry {
                            CBTICard {
                                Text("Log what happened. CBTI works best with real nights.")
                                    .font(Theme.bodyFont)
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.hPad)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
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

    private func applyPlannedBedtimeOffset(_ offset: Int) {
        guard let plannedWindow else { return }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: plannedWindow.start)
        let minute = calendar.component(.minute, from: plannedWindow.start)
        let base = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: draft.bedtime) ?? draft.bedtime
        updateDraftTimes(
            bedtime: base.addingTimeInterval(TimeInterval(offset * 60)),
            wakeTime: draft.wakeTime
        )
    }

    private func updateDraftTimes(bedtime: Date, wakeTime: Date) {
        let normalized = normalizedSleepRange(bedtime: bedtime, wakeTime: wakeTime)
        draft.bedtime = normalized.bedtime
        draft.wakeTime = normalized.wakeTime
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

            Text("Tap when you get into bed. You can fix it tomorrow.")
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
            Text("If you can't fall asleep, use the guidance below.")
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
                    Text("A rough night doesn't mean the plan failed. Keep wake time stable and log the morning.")
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

// MARK: - History Screen

private struct SleepHistoryView: View {
    let entries: [SleepDiaryEntry]
    let onEdit: (SleepDiaryEntry) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.cardGap) {
                Text("History")
                    .font(Theme.largeTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)

                SleepProgressSummary(entries: entries)

                if entries.isEmpty {
                    CBTICard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No sleep logs yet")
                                .font(Theme.headlineFont)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Your logs show up here. Tap a night to edit.")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Text("Sleep Logs")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.textPrimary)

                    ForEach(entries) { entry in
                        Button {
                            onEdit(entry)
                        } label: {
                            HistoryEntryCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Theme.hPad)
            .padding(.bottom, 100)
        }
    }
}

private struct HistoryEntryCard: View {
    let entry: SleepDiaryEntry

    var body: some View {
        CBTICard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateText)
                                .font(Theme.headlineFont)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Tap to edit")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textMuted)
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

    private var dateText: String {
        historyDateFormatter.string(from: entry.date)
    }

    private var latencyText: String {
        guard let latency = entry.sleepLatencyMinutes else { return "--" }
        return "\(latency)m"
    }
}

private struct SleepProgressSummary: View {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)

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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.textMuted)
                            Text("Need at least 2 logs to show trends")
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
    }
}

// MARK: - Progress Screen

private struct SleepProgressView: View {
    let entries: [SleepDiaryEntry]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.cardGap) {
                Text("Progress")
                    .font(Theme.largeTitleFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 16)

                SleepProgressSummary(entries: entries)
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
                let requestedWake = Calendar.current.date(
                    bySettingHour: wakeHour,
                    minute: wakeMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
                return clampedTargetWakeDate(requestedWake)
            },
            set: {
                let rounded = clampedTargetWakeDate($0)
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
                        SingleTimeSliderView(
                            title: "Target Wake Time",
                            subtitle: nil,
                            date: wakeDate,
                            bounds: targetWakeBoundsMinutes
                        )
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
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private let historyDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

// Testing only. Set to false or comment out the seed block in `seedIfNeeded()`.
private let enableMockSleepSeedData = true

private let targetWakeBoundsMinutes: ClosedRange<Int> = (6 * 60)...(12 * 60)

private struct MockSleepSeedSample {
    let bedtimeHour: Int
    let bedtimeMinute: Int
    let wakeHour: Int
    let wakeMinute: Int
    let latencyMinutes: Int
    let quality: Int
    let awakenings: Int
    let caffeineIntake: Bool
    let screenTimeMinutes: Int
}

private let mockSleepSeedEntries: [MockSleepSeedSample] = [
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 40, wakeHour: 7, wakeMinute: 45, latencyMinutes: 20, quality: 7, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 35),
    MockSleepSeedSample(bedtimeHour: 0, bedtimeMinute: 5, wakeHour: 8, wakeMinute: 0, latencyMinutes: 30, quality: 6, awakenings: 2, caffeineIntake: true, screenTimeMinutes: 50),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 25, wakeHour: 7, wakeMinute: 30, latencyMinutes: 15, quality: 8, awakenings: 0, caffeineIntake: false, screenTimeMinutes: 20),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 55, wakeHour: 7, wakeMinute: 50, latencyMinutes: 25, quality: 6, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 40),
    MockSleepSeedSample(bedtimeHour: 0, bedtimeMinute: 20, wakeHour: 8, wakeMinute: 10, latencyMinutes: 40, quality: 5, awakenings: 2, caffeineIntake: true, screenTimeMinutes: 65),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 10, wakeHour: 7, wakeMinute: 20, latencyMinutes: 15, quality: 8, awakenings: 0, caffeineIntake: false, screenTimeMinutes: 25),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 35, wakeHour: 7, wakeMinute: 40, latencyMinutes: 20, quality: 7, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 30),
    MockSleepSeedSample(bedtimeHour: 0, bedtimeMinute: 15, wakeHour: 8, wakeMinute: 15, latencyMinutes: 35, quality: 5, awakenings: 3, caffeineIntake: true, screenTimeMinutes: 70),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 5, wakeHour: 7, wakeMinute: 10, latencyMinutes: 10, quality: 8, awakenings: 0, caffeineIntake: false, screenTimeMinutes: 15),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 50, wakeHour: 7, wakeMinute: 55, latencyMinutes: 30, quality: 6, awakenings: 2, caffeineIntake: true, screenTimeMinutes: 45),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 20, wakeHour: 7, wakeMinute: 35, latencyMinutes: 15, quality: 7, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 30),
    MockSleepSeedSample(bedtimeHour: 0, bedtimeMinute: 0, wakeHour: 8, wakeMinute: 5, latencyMinutes: 25, quality: 6, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 35),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 30, wakeHour: 7, wakeMinute: 25, latencyMinutes: 20, quality: 7, awakenings: 1, caffeineIntake: false, screenTimeMinutes: 25),
    MockSleepSeedSample(bedtimeHour: 23, bedtimeMinute: 45, wakeHour: 7, wakeMinute: 50, latencyMinutes: 15, quality: 8, awakenings: 0, caffeineIntake: false, screenTimeMinutes: 20)
]

private func roundedToQuarterHour(_ date: Date) -> Date {
    let interval = 15.0 * 60.0
    let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded() * interval
    return Date(timeIntervalSinceReferenceDate: rounded)
}

private func clampedTargetWakeDate(_ date: Date) -> Date {
    let rounded = roundedToQuarterHour(date)
    let components = Calendar.current.dateComponents([.hour, .minute], from: rounded)
    let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
    let clampedMinutes = min(max(minutes, targetWakeBoundsMinutes.lowerBound), targetWakeBoundsMinutes.upperBound)
    let hour = clampedMinutes / 60
    let minute = clampedMinutes % 60
    return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: rounded) ?? rounded
}

private func currentWeekKey() -> Int {
    let calendar = Calendar.current
    return calendar.component(.year, from: Date()) * 100 + calendar.component(.weekOfYear, from: Date())
}

private func mockBedtimeBaseDate(for sample: MockSleepSeedSample, wakeDay: Date) -> Date {
    let bedtimeMinutes = sample.bedtimeHour * 60 + sample.bedtimeMinute
    let wakeMinutes = sample.wakeHour * 60 + sample.wakeMinute
    if bedtimeMinutes > wakeMinutes {
        return Calendar.current.date(byAdding: .day, value: -1, to: wakeDay) ?? wakeDay.addingTimeInterval(-24 * 3600)
    }
    return wakeDay
}

private func sleepEditorBounds(for wakeReference: Date) -> ClosedRange<Date> {
    let wakeDay = Calendar.current.startOfDay(for: wakeReference)
    let lowerBound = wakeDay.addingTimeInterval(-3 * 3600)
    let upperBound = wakeDay.addingTimeInterval(12 * 3600)
    return lowerBound...upperBound
}

private func normalizedSleepRange(
    bedtime: Date,
    wakeTime: Date,
    minimumGapMinutes: Int = 15
) -> (bedtime: Date, wakeTime: Date) {
    let gap = TimeInterval(minimumGapMinutes * 60)
    let roundedWake = roundedToQuarterHour(wakeTime)
    let bounds = sleepEditorBounds(for: roundedWake)
    let clampedWake = min(max(roundedWake, bounds.lowerBound.addingTimeInterval(gap)), bounds.upperBound)
    let roundedBedtime = roundedToQuarterHour(bedtime)
    let latestBedtime = clampedWake.addingTimeInterval(-gap)
    let clampedBedtime = min(max(roundedBedtime, bounds.lowerBound), latestBedtime)
    return (bedtime: clampedBedtime, wakeTime: clampedWake)
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
