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
                        }

                        if !store.pastShifts.isEmpty {
                            VStack(spacing: 12) {
                                sectionLabel("Past Shifts")
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
        }
        .padding(18)
        .neonCard()
    }
}

// MARK: - PastShiftRow

private struct PastShiftRow: View {
    let record: ShiftRecord

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(record.date, style: .date)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 14) {
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
            Text(record.totalEarnings, format: .currency(code: "USD"))
                .font(.headline.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .neonCard(glow: AppTheme.borderSubtle)
    }
}

#Preview {
    AnalyticsView()
        .environment(ShiftStore())
}
