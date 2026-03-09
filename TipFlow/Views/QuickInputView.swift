import SwiftUI

/// Grid of large, tap-friendly buttons for quickly logging common earnings.
struct QuickInputView: View {
    @EnvironmentObject var viewModel: ShiftViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Lap Dance buttons
            HStack(spacing: 12) {
                quickButton(
                    label: "+$20",
                    subtitle: "Lap Dance",
                    color: .purple
                ) {
                    viewModel.addEarning(amount: 20, category: .lapDance)
                }

                quickButton(
                    label: "+$40",
                    subtitle: "Lap Dance",
                    color: .purple
                ) {
                    viewModel.addEarning(amount: 40, category: .lapDance)
                }
            }

            // Stage Tip buttons
            HStack(spacing: 12) {
                quickButton(
                    label: "+$5",
                    subtitle: "Stage Tip",
                    color: .blue
                ) {
                    viewModel.addEarning(amount: 5, category: .stageTip)
                }

                quickButton(
                    label: "+$10",
                    subtitle: "Stage Tip",
                    color: .blue
                ) {
                    viewModel.addEarning(amount: 10, category: .stageTip)
                }
            }

            // Random Tip and Custom
            HStack(spacing: 12) {
                quickButton(
                    label: "+$20",
                    subtitle: "Random Tip",
                    color: .orange
                ) {
                    viewModel.addEarning(amount: 20, category: .randomTip)
                }

                quickButton(
                    label: "Custom",
                    subtitle: "Amount",
                    color: .gray
                ) {
                    viewModel.showCustomAmountSheet = true
                }
            }
        }
    }

    private func quickButton(
        label: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
