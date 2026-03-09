// AnalyticsView.swift — TipFlow
// Shift performance stats: earnings, hourly rate, interaction metrics, past shifts.

import SwiftUI

struct AnalyticsView: View {
    @Environment(ShiftStore.self) private var store

    private var shift: Shift { store.currentShift }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Current shift ─────────────────────────────────
                        sectionLabel("Current Shift")

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            StatCard(
                                title: "Total Earnings",
                                value: shift.totalEarnings.formatted(.currency(code: "USD")),
                                icon: "dollarsign.circle.fill",
                                color: .pink
                            )
                            StatCard(
                                title: "Per Hour",
                                value: shift.earningsPerHour > 0
                                    ? shift.earningsPerHour.formatted(.currency(code: "USD"))
                                    : "—",
                                icon: "clock.fill",
                                color: .orange
                            )
                            StatCard(
                                title: "Interactions",
                                value: "\(shift.interactions.count)",
                                icon: "person.2.fill",
                                color: .blue
                            )
                            StatCard(
                                title: "Conversion",
                                value: shift.completedInteractions.isEmpty
                                    ? "—"
                                    : "\(Int(shift.conversionRate * 100))%",
                                icon: "arrow.up.right.circle.fill",
                                color: .green
                            )
                        }

                        // ── Average interaction duration ──────────────────
                        if !shift.completedInteractions.isEmpty {
                            AvgDurationCard(duration: shift.averageInteractionDuration)
                        }

                        // ── Earnings breakdown chart ───────────────────────
                        if shift.totalEarnings > 0 {
                            EarningsBreakdownChart(shift: shift)
                        }

                        // ── Past shifts history ───────────────────────────
                        if !store.pastShifts.isEmpty {
                            VStack(spacing: 12) {
                                sectionLabel("Past Shifts")
                                ForEach(store.pastShifts.prefix(10)) { record in
                                    PastShiftRow(record: record)
                                }
                            }
                        }

                        // Empty state
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analytics")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.15))
            Text("No data yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))
            Text("Start logging earnings on the Dashboard\nto see your analytics here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.25))
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
                    .foregroundStyle(.white.opacity(0.55))
                Text(formatted)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("before conversion")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 38))
                .foregroundStyle(.purple.opacity(0.55))
        }
        .padding(18)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - EarningsBreakdownChart

private struct EarningsBreakdownChart: View {
    let shift: Shift

    private struct Segment {
        let label: String
        let amount: Double
        let color: Color
    }

    private var segments: [Segment] {
        [
            Segment(label: "Lap Dances",  amount: shift.lapDanceTotal,  color: .pink),
            Segment(label: "Stage Tips",  amount: shift.stageTipTotal,  color: .purple),
            Segment(label: "Random Tips", amount: shift.randomTipTotal, color: .teal),
        ].filter { $0.amount > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Earnings Breakdown")

            ForEach(segments, id: \.label) { seg in
                VStack(spacing: 6) {
                    HStack {
                        Circle()
                            .fill(seg.color)
                            .frame(width: 8, height: 8)
                        Text(seg.label)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(seg.amount, format: .currency(code: "USD"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 8)
                            Capsule()
                                .fill(seg.color)
                                .frame(
                                    width: shift.totalEarnings > 0
                                        ? geo.size.width * CGFloat(seg.amount / shift.totalEarnings)
                                        : 0,
                                    height: 8
                                )
                                .animation(.spring(duration: 0.6, bounce: 0.1), value: seg.amount)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(18)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    Label(
                        "\(record.interactionCount) interaction\(record.interactionCount == 1 ? "" : "s")",
                        systemImage: "person.2"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))

                    Label(
                        "\(Int(record.conversionRate * 100))% conv.",
                        systemImage: "arrow.up.right"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))

                    if record.durationHours > 0 {
                        Label(
                            String(format: "%.1fh", record.durationHours),
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            Spacer()
            Text(record.totalEarnings, format: .currency(code: "USD"))
                .font(.headline.bold())
                .foregroundStyle(.white)
        }
        .padding(14)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
        .environment(ShiftStore())
}
