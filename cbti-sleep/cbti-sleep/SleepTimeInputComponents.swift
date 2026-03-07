import SwiftUI

struct SleepRangeTimelineView: View {
    let title: String
    let subtitle: String?
    @Binding var startDate: Date
    @Binding var endDate: Date
    var accent: Color = Theme.indigo
    var minimumGapMinutes: Int = 15

    @State private var dragOriginStart: Date?
    @State private var dragOriginEnd: Date?
    @State private var referenceWake: Date?
    @State private var lastSnappedStart: Date?
    @State private var lastSnappedEnd: Date?
    @State private var isDragging = false

    private let handleSize: CGFloat = 28
    private let handleLabelWidth: CGFloat = 90
    private let trackHeight: CGFloat = 12

    private var bounds: ClosedRange<Date> {
        Self.fixedTimelineBounds(for: referenceWake ?? endDate)
    }

    private var trackInset: CGFloat {
        handleLabelWidth / 2
    }

    private var hourMarks: [Date] {
        var marks: [Date] = []
        var cursor = bounds.lowerBound
        while cursor <= bounds.upperBound {
            marks.append(cursor)
            cursor = cursor.addingTimeInterval(2 * 3600)
        }
        return marks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                let trackWidth = max(width - trackInset * 2, 1)
                let startX = xPosition(for: startDate, width: width)
                let endX = xPosition(for: endDate, width: width)

                ZStack(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: trackWidth, height: trackHeight)
                        .offset(x: trackInset, y: 38)

                    Capsule(style: .continuous)
                        .fill(accent.gradient)
                        .frame(width: max(endX - startX, 0), height: trackHeight)
                        .offset(x: startX, y: 38)

                    ForEach(hourMarks, id: \.self) { mark in
                        let x = xPosition(for: mark, width: width)
                        VStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 1, height: 10)
                            Text(Self.hourLabel(for: mark))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .position(x: clampedLabelX(x, width: width), y: 64)
                    }

                    timelineHandle(
                        label: "Bedtime",
                        timeText: Self.timeText(for: startDate),
                        x: startX,
                        accent: accent,
                        width: width,
                        isLeading: true
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                if dragOriginStart == nil { dragOriginStart = startDate }
                                guard let dragOriginStart else { return }
                                let secondsPerPoint = bounds.upperBound.timeIntervalSince(bounds.lowerBound) / trackWidth
                                let moved = dragOriginStart.addingTimeInterval(TimeInterval(value.translation.width) * secondsPerPoint)
                                let snapped = Self.snapDate(moved)
                                let latestStart = endDate.addingTimeInterval(TimeInterval(-minimumGapMinutes * 60))
                                let clamped = min(max(snapped, bounds.lowerBound), latestStart)
                                if lastSnappedStart != clamped {
                                    lastSnappedStart = clamped
                                    startDate = clamped
                                }
                            }
                            .onEnded { _ in
                                dragOriginStart = nil
                                lastSnappedStart = nil
                                isDragging = false
                            }
                    )

                    timelineHandle(
                        label: "Wake",
                        timeText: Self.timeText(for: endDate),
                        x: endX,
                        accent: accent,
                        width: width,
                        isLeading: false
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                if dragOriginEnd == nil { dragOriginEnd = endDate }
                                guard let dragOriginEnd else { return }
                                let secondsPerPoint = bounds.upperBound.timeIntervalSince(bounds.lowerBound) / trackWidth
                                let moved = dragOriginEnd.addingTimeInterval(TimeInterval(value.translation.width) * secondsPerPoint)
                                let snapped = Self.snapDate(moved)
                                let earliestEnd = startDate.addingTimeInterval(TimeInterval(minimumGapMinutes * 60))
                                let clamped = max(min(snapped, bounds.upperBound), earliestEnd)
                                if lastSnappedEnd != clamped {
                                    lastSnappedEnd = clamped
                                    endDate = clamped
                                }
                            }
                            .onEnded { _ in
                                dragOriginEnd = nil
                                lastSnappedEnd = nil
                                isDragging = false
                            }
                    )
                }
            }
            .frame(height: 88)
            .onAppear {
                if referenceWake == nil { referenceWake = endDate }
            }
            .onChange(of: endDate) { _, newValue in
                if !isDragging {
                    referenceWake = newValue
                }
            }

            HStack(spacing: 12) {
                timelineValueCard(title: "In bed", value: Self.durationText(from: endDate.timeIntervalSince(startDate)))
                timelineValueCard(title: "Wake", value: Self.timeText(for: endDate))
            }
        }
    }

    private func timelineHandle(
        label: String,
        timeText: String,
        x: CGFloat,
        accent: Color,
        width: CGFloat,
        isLeading: Bool
    ) -> some View {
        VStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textMuted)
                Text(timeText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            Circle()
                .fill(accent)
                .frame(width: handleSize, height: handleSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.65), lineWidth: 3)
                )
                .shadow(color: accent.opacity(0.45), radius: 10, y: 4)
        }
        .frame(width: max(90, 44), height: 88, alignment: .top)
        .contentShape(Rectangle())
        .position(
            x: x,
            y: 24
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(timeText)
        .accessibilityHint(isLeading ? "Drag left or right to change bedtime" : "Drag left or right to change wake time")
    }

    private func timelineValueCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.bgSecondary.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func xPosition(for date: Date, width: CGFloat) -> CGFloat {
        let span = bounds.upperBound.timeIntervalSince(bounds.lowerBound)
        let travelWidth = max(width - trackInset * 2, 1)
        guard span > 0 else { return trackInset }
        let offset = date.timeIntervalSince(bounds.lowerBound)
        return trackInset + CGFloat(min(max(offset / span, 0), 1)) * travelWidth
    }

    private func clampedLabelX(_ x: CGFloat, width: CGFloat) -> CGFloat {
        min(max(x, 14), width - 14)
    }

    private static func fixedTimelineBounds(for wakeTime: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let wakeDay = calendar.startOfDay(for: wakeTime)
        let lower = wakeDay.addingTimeInterval(-3 * 3600)
        let upper = wakeDay.addingTimeInterval(12 * 3600)
        return lower...upper
    }

    private static func snapDate(_ date: Date) -> Date {
        let interval = 15.0 * 60.0
        let rounded = (date.timeIntervalSinceReferenceDate / interval).rounded() * interval
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    private static func hourLabel(for date: Date) -> String {
        hourFormatter.string(from: date)
    }

    private static func timeText(for date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    private static func durationText(from interval: TimeInterval) -> String {
        guard interval > 0 else { return "--" }
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        return "\(hours)h \(minutes)m"
    }

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("HH")
        return formatter
    }()
}

struct SingleTimeSliderView: View {
    let title: String
    let subtitle: String?
    @Binding var date: Date
    var bounds: ClosedRange<Int> = 0...(24 * 60 - 15)
    var accent: Color = Theme.indigo

    @State private var dragOriginMinutes: Int?
    @State private var lastSnappedMinutes: Int?

    private let knobSize: CGFloat = 28
    private let touchTargetSize: CGFloat = 44

    private var currentMinutes: Int {
        Self.minutesSinceMidnight(for: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)

                Text(Self.timeText(for: date))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                let knobX = positionX(for: currentMinutes, width: width)

                ZStack(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 12)
                        .offset(y: 24)

                    Capsule(style: .continuous)
                        .fill(accent.gradient)
                        .frame(width: knobX, height: 12)
                        .offset(y: 24)

                    HStack {
                        Text(Self.timeLabel(from: bounds.lowerBound))
                        Spacer()
                        Text(Self.timeLabel(from: bounds.upperBound))
                    }
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textMuted)
                    .offset(y: 48)

                    VStack(spacing: 6) {
                        Text(Self.timeText(for: date))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )

                        Circle()
                            .fill(accent)
                            .frame(width: knobSize, height: knobSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.65), lineWidth: 3)
                            )
                    }
                    .frame(width: max(touchTargetSize, 76), height: 76, alignment: .top)
                    .contentShape(Rectangle())
                    .position(x: min(max(knobX, 22), width - 22), y: 18)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if dragOriginMinutes == nil { dragOriginMinutes = currentMinutes }
                                guard let dragOriginMinutes else { return }
                                let minutesPerPoint = Double(bounds.upperBound - bounds.lowerBound) / width
                                let moved = Double(dragOriginMinutes) + Double(value.translation.width) * minutesPerPoint
                                let snapped = Self.snapMinutes(Int(moved.rounded()))
                                let clamped = min(max(snapped, bounds.lowerBound), bounds.upperBound)
                                if lastSnappedMinutes != clamped {
                                    lastSnappedMinutes = clamped
                                    date = Self.date(bySettingMinutesSinceMidnight: clamped, on: date)
                                }
                            }
                            .onEnded { _ in
                                dragOriginMinutes = nil
                                lastSnappedMinutes = nil
                            }
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(title)
                    .accessibilityValue(Self.timeText(for: date))
                    .accessibilityHint("Drag left or right to change time")
                }
            }
            .frame(height: 80)
        }
    }

    private func positionX(for minutes: Int, width: CGFloat) -> CGFloat {
        let denominator = max(bounds.upperBound - bounds.lowerBound, 1)
        let progress = CGFloat(minutes - bounds.lowerBound) / CGFloat(denominator)
        return min(max(progress, 0), 1) * width
    }

    private static func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func date(bySettingMinutesSinceMidnight minutes: Int, on date: Date) -> Date {
        let rounded = snapMinutes(minutes)
        let hour = rounded / 60
        let minute = rounded % 60
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private static func snapMinutes(_ minutes: Int) -> Int {
        let step = 15
        return Int((Double(minutes) / Double(step)).rounded()) * step
    }

    private static func timeLabel(from minutes: Int) -> String {
        let clamped = max(minutes, 0)
        let hour = (clamped / 60) % 24
        let minute = clamped % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private static func timeText(for date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct TimeOffsetChipsView: View {
    let title: String
    let baseTimeText: String
    let offsets: [Int]
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                Text(baseTimeText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 10)], spacing: 10) {
                ForEach(offsets, id: \.self) { offset in
                    Button {
                        onSelect(offset)
                    } label: {
                        Text(Self.offsetLabel(offset))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 10)
                            .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Adjust by \(Self.offsetLabel(offset))")
                }
            }
        }
    }

    private static func offsetLabel(_ minutes: Int) -> String {
        if minutes % 60 == 0 {
            return "+\(minutes / 60)h"
        }
        return "+\(minutes)m"
    }
}

struct DateStepperField: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                Text(Self.dayText(for: date))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            dateButton(systemName: "chevron.left", delta: -1)
            dateButton(systemName: "chevron.right", delta: 1)
        }
        .padding(14)
        .background(Theme.bgSecondary.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dateButton(systemName: String, delta: Int) -> some View {
        Button {
            let shifted = Calendar.current.date(byAdding: .day, value: delta, to: date) ?? date
            date = shifted
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 44, height: 44)
                .background(Theme.cardBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(delta < 0 ? "Previous day" : "Next day")
    }

    private static func dayText(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return formatter
    }()
}

struct SelectionChipGroup<Value: Hashable>: View {
    let title: String
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button {
                        selection = option
                    } label: {
                        Text(label(option))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(isSelected ? Theme.indigo.opacity(0.28) : Theme.bgSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isSelected ? Theme.indigo : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
