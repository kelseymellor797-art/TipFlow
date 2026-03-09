import SwiftUI

/// Analytics screen showing shift performance metrics.
struct AnalyticsView: View {
    @EnvironmentObject var viewModel: ShiftViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    analyticsCard(
                        title: "Total Earnings",
                        value: ShiftViewModel.formatCurrency(viewModel.currentShift.totalEarnings),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )

                    analyticsCard(
                        title: "Avg Earnings / Hour",
                        value: ShiftViewModel.formatCurrency(viewModel.averageEarningsPerHour),
                        icon: "clock.fill",
                        color: .blue
                    )

                    analyticsCard(
                        title: "Total Interactions",
                        value: "\(viewModel.currentShift.interactionCount)",
                        icon: "person.2.fill",
                        color: .purple
                    )

                    analyticsCard(
                        title: "Conversion Rate",
                        value: String(format: "%.0f%%", viewModel.currentShift.conversionRate * 100),
                        icon: "arrow.triangle.2.circlepath",
                        color: .orange
                    )

                    analyticsCard(
                        title: "Avg Interaction Length",
                        value: ShiftViewModel.formatTime(viewModel.averageInteractionLength),
                        icon: "timer",
                        color: .pink
                    )

                    // Earnings breakdown
                    earningsBreakdown
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }

    private func analyticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var earningsBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earnings Breakdown")
                .font(.headline)
                .foregroundColor(.secondary)

            breakdownRow(
                label: "Lap Dances",
                amount: viewModel.currentShift.lapDanceEarnings,
                color: .purple
            )
            breakdownRow(
                label: "Stage Tips",
                amount: viewModel.currentShift.stageTipEarnings,
                color: .blue
            )
            breakdownRow(
                label: "Random Tips",
                amount: viewModel.currentShift.randomTipEarnings,
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func breakdownRow(label: String, amount: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.body)
            Spacer()
            Text(ShiftViewModel.formatCurrency(amount))
                .font(.body.bold())
                .foregroundColor(color)
        }
    }
}
