// AnalyticsView.swift — TipFlow
// Shift performance stats: earnings, hourly rate, interaction metrics, past shifts.

import SwiftUI

struct AnalyticsView: View {
    @Environment(ShiftStore.self) private var store

    private var shift: Shift { store.currentShift }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        sectionLabel("Current Shift")

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            StatCard(
                                title:    "Total Earnings",
                                value:    shift.totalEarnings.formatted(.currency(code: "USD")),
                                icon:     "dollarsign.circle.fill",
                                gradient: AppTheme.primaryGradient
                            )
                            StatCard(
                                title:    "Per Hour",
                                value:    shift.earningsPerHour > 0
                                    ? shift.earningsPerHour.formatted(.currency(code: "USD"))
                                    : "--",
                                icon:     "clock.fill",
                                gradient: AppTheme.blueGradient
                            )
                            StatCard(
                                title:    "Interactions",
                                value:    "\(shift.interactions.count)",
                                icon:     "person.2.fill",
                                gradient: AppTheme.blueGradient
                            )
                            StatCard(
                                title:    "Conversion",
                                value:    shift.completedInteractions.isEmpty
                                    ? "--"
                                    : "\(Int(shift.conversionRate * 100))%",
                                icon:     "arrow.up.right.circle.fill",
                                gradient: AppTheme.tealGradient
                            )
                        }

                        if !shift.completedInteractions.isEmpty {
                            AvgDurationCard(duration: shift.averageInteractionDuration)
                        }

                        if shift.totalEarnings > 0 {
                            EarningsBreakdownChart(shift: shift)
                            HourlyBreakdownView(shift: shift)
                            if shift.totalEarnings > 30 && shift.stageTipTotal / shift.totalEarnings < 0.15 {
                                StageTipCoachCard(shift: shift)
                            }
                            if !shift.expenses.isEmpty {
                                ExpenseBreakdownCard(shift: shift)
                            }
                        }

                        if !store.pastShifts.isEmpty {
                            VStack(spacing: 12) {
                                sectionLabel("Past Shifts")
                                bestShiftBanner
                                ForEach(store.pastShifts.prefix(10)) { record in
                                    PastShiftRow(record: record)
                                }
                            }
                        }

                        if shift.totalEarnings == 0 && store.pastShifts.isEmpty {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analytics")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private var bestShiftBanner: some View {
        let thisMonthShifts = store.pastShifts.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        if let best = thisMonthShifts.max(by: { $0.totalEarnings < $1.totalEarnings }) {
            BestShiftBanner(record: best)
        }
    }

    @ViewBuilder
    private func sectionLabel(_ title: String) -> some View {
        SectionHeader(title: title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.textTertiary)
            Text("No data yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Start logging earnings on the Dashboard\nto see your analytics here.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - AvgDurationCard

private struct AvgDurationCard: View {
    let duration: TimeInterval

    private var formatted: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Avg Interaction Length")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(formatted)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("before conversion")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 38))
                .foregroundStyle(AppTheme.blueGradient)
        }
        .padding(18)
        .neonCard(glow: AppTheme.neonBlue.opacity(0.30))
    }
}

// MARK: - EarningsBreakdownChart

private struct EarningsBreakdownChart: View {
    let shift: Shift

    private struct Segment {
        let label: String
        let amount: Double
        let gradient: LinearGradient
    }

    private var segments: [Segment] {
        [
            Segment(label: "Lap Dances",  amount: shift.lapDanceTotal,  gradient: AppTheme.primaryGradient),
            Segment(label: "Stage Tips",  amount: shift.stageTipTotal,  gradient: AppTheme.blueGradient),
            Segment(label: "Random Tips", amount: shift.randomTipTotal, gradient: AppTheme.tealGradient),
        ].filter { $0.amount > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Earnings Breakdown")

            ForEach(segments, id: \.label) { seg in
                VStack(spacing: 6) {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(seg.gradient)
                            .frame(width: 10, height: 10)
                        Text(seg.label)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(Int(seg.amount / max(shift.totalEarnings, 1) * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(seg.amount, format: .currency(code: "USD"))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 8)
                            Capsule()
                                .fill(seg.gradient)
                                .frame(
                                    width: shift.totalEarnings > 0
                                        ? geo.size.width * CGFloat(seg.amount / shift.totalEarnings)
                                        : 0,
                                    height: 8
                                )
                                .animation(.spring(duration: 0.6, bounce: 0.1), value: seg.amount)
                                .shadow(color: AppTheme.neonPink.opacity(0.3), radius: 4, y: 2)
                        }
                    }
                    .frame(height: 8)
                }
            }

            if let topSeg = segments.max(by: { $0.amount < $1.amount }) {
                HStack(spacing: 6) {
                    Label("Most profitable tonight: \(topSeg.label)", systemImage: "trophy.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .neonCard()
    }
}

// MARK: - HourlyBreakdownView

private struct HourlyBreakdownView: View {
    let shift: Shift

    private var hours: [HourlyEarning] { shift.hourlyBreakdown }
    private var maxTotal: Double { hours.max(by: { $0.total < $1.total })?.total ?? 1 }
    private var bestHourID: Int? { hours.max(by: { $0.total < $1.total })?.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Best Hour")
            ForEach(hours) { earning in
                HourEarningRow(
                    earning: earning,
                    maxTotal: maxTotal,
                    isBest: earning.id == bestHourID
                )
            }
        }
        .padding(18)
        .neonCard()
    }
}

private struct HourEarningRow: View {
    let earning: HourlyEarning
    let maxTotal: Double
    let isBest: Bool

    private var barGradient: LinearGradient {
        if isBest {
            return AppTheme.primaryGradient
        } else {
            return AppTheme.blueGradient
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let end = (hour + 1) % 24
        return "\(hourString(hour))–\(hourString(end))"
    }

    private func hourString(_ hour: Int) -> String {
        if hour == 0  { return "12AM" }
        if hour == 12 { return "12PM" }
        if hour < 12  { return "\(hour)AM" }
        return "\(hour - 12)PM"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(hourLabel(earning.hour))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 82, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)
                    Capsule()
                        .fill(barGradient)
                        .frame(
                            width: geo.size.width * CGFloat(earning.total / max(maxTotal, 1)),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            Text(earning.total, format: .currency(code: "USD"))
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 55, alignment: .trailing)

            if isBest {
                Text("Best")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.neonPink.opacity(0.20))
                    .foregroundStyle(AppTheme.neonPink)
                    .clipShape(Capsule())
            } else {
                Text("Best")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .opacity(0)
            }
        }
    }
}

// MARK: - StageTipCoachCard

private struct StageTipCoachCard: View {
    let shift: Shift

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))

            VStack(alignment: .leading, spacing: 5) {
                Text("Stage Tip Strategy")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(
                    shift.stageTipTotal == 0
                        ? "No stage tips logged yet — a high-energy set can change that."
                        : "Stage tips are \(Int(shift.stageTipTotal / shift.totalEarnings * 100))% of earnings tonight — try a high-energy set to boost them."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .neonCard(glow: Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.25))
    }
}

// MARK: - ExpenseBreakdownCard

private struct ExpenseBreakdownCard: View {
    let shift: Shift

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Expenses")

            ForEach(shift.expenses) { expense in
                HStack(spacing: 12) {
                    Image(systemName: expense.type.icon)
                        .font(.body)
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.35))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(expense.type.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                        if !expense.note.isEmpty {
                            Text(expense.note)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }

                    Spacer()

                    Text(expense.amount, format: .currency(code: "USD"))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.35))
                }
            }

            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 1)

            HStack {
                Text("Total Expenses")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(shift.totalExpenses, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.35))
            }

            HStack {
                Text("Net Profit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(shift.netProfit, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 0.10, green: 0.85, blue: 0.80))
            }
        }
        .padding(18)
        .neonCard()
    }
}

// MARK: - BestShiftBanner

private struct BestShiftBanner: View {
    let record: ShiftRecord

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))

            VStack(alignment: .leading, spacing: 3) {
                Text("Best Shift This Month")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
                    .textCase(.uppercase)
                    .kerning(0.8)

                Text(record.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text(record.totalEarnings, format: .currency(code: "USD"))
                .font(.headline.bold())
                .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
        }
        .padding(14)
        .background(
            ZStack {
                AppTheme.cardBg
                Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.06)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.35), lineWidth: 3)
        )
    }
}

// MARK: - PastShiftRow

private struct PastShiftRow: View {
    let record: ShiftRecord

    private var ratePerHour: Double {
        record.durationHours > 0 ? record.totalEarnings / record.durationHours : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, format: Date.FormatStyle().weekday(.wide))
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 10) {
                    Label(
                        "\(record.interactionCount) interaction\(record.interactionCount == 1 ? "" : "s")",
                        systemImage: "person.2"
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)

                    Label(
                        "\(Int(record.conversionRate * 100))% conv.",
                        systemImage: "arrow.up.right"
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)

                    if record.durationHours > 0 {
                        Label(
                            String(format: "%.1fh", record.durationHours),
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.totalEarnings, format: .currency(code: "USD"))
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                if ratePerHour > 0 {
                    Text("\(ratePerHour.formatted(.currency(code: "USD")))/hr")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                if record.netProfit < record.totalEarnings {
                    Text("Net: \(record.netProfit.formatted(.currency(code: "USD")))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.10, green: 0.85, blue: 0.80))
                }
            }
        }
        .padding(14)
        .neonCard(glow: AppTheme.borderSubtle)
    }
}

#Preview {
    AnalyticsView()
        .environment(ShiftStore())
}
