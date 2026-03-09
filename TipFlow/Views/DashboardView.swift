import SwiftUI

/// Main dashboard showing shift earnings, progress, active interaction, and quick input buttons.
struct DashboardView: View {
    @EnvironmentObject var viewModel: ShiftViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    earningsSummaryCard
                    goalProgressBar
                    interactionSection
                    QuickInputView()
                }
                .padding()
            }
            .navigationTitle("TipFlow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Shift") {
                        viewModel.startNewShift()
                    }
                    .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $viewModel.showEndInteractionSheet) {
            EndInteractionView()
        }
        .sheet(isPresented: $viewModel.showCustomAmountSheet) {
            CustomAmountView()
        }
    }

    // MARK: - Earnings Summary

    private var earningsSummaryCard: some View {
        VStack(spacing: 12) {
            Text(ShiftViewModel.formatCurrency(viewModel.currentShift.totalEarnings))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.green)

            HStack(spacing: 24) {
                earningLabel(
                    title: "Dances",
                    amount: viewModel.currentShift.lapDanceEarnings,
                    color: .purple
                )
                earningLabel(
                    title: "Stage",
                    amount: viewModel.currentShift.stageTipEarnings,
                    color: .blue
                )
                earningLabel(
                    title: "Tips",
                    amount: viewModel.currentShift.randomTipEarnings,
                    color: .orange
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func earningLabel(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(ShiftViewModel.formatCurrency(amount))
                .font(.title3.bold())
                .foregroundColor(color)
        }
    }

    // MARK: - Goal Progress

    private var goalProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Goal: \(ShiftViewModel.formatCurrency(viewModel.currentShift.goalAmount))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(viewModel.progressTowardGoal * 100))%")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
            ProgressView(value: viewModel.progressTowardGoal)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Interaction Section

    private var interactionSection: some View {
        Group {
            if let _ = viewModel.activeInteraction {
                InteractionTimerView()
            } else {
                Button(action: { viewModel.startInteraction() }) {
                    HStack {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.title2)
                        Text("Start Interaction")
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
        }
    }
}
