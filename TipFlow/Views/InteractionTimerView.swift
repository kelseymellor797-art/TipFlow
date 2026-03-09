import SwiftUI

/// Displays the active interaction timer with controls to extend, convert, or end.
struct InteractionTimerView: View {
    @EnvironmentObject var viewModel: ShiftViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Timer display
            VStack(spacing: 4) {
                Text("Active Interaction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(ShiftViewModel.formatTime(viewModel.interactionElapsedTime))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            // Time prompt (appears at 1 minute)
            if viewModel.showInteractionPrompt {
                interactionPrompt
            }

            // End / Cancel buttons
            HStack(spacing: 12) {
                Button(action: { viewModel.showEndInteractionSheet = true }) {
                    Text("End Interaction")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { viewModel.cancelInteraction() }) {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(.systemGray5))
                        .foregroundColor(.secondary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Interaction Prompt

    private var interactionPrompt: some View {
        VStack(spacing: 12) {
            Text("Interaction reaching 1 minute. Continue?")
                .font(.subheadline)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                promptButton(title: "+2 min") {
                    viewModel.extendInteraction(minutes: 2)
                }
                promptButton(title: "+5 min") {
                    viewModel.extendInteraction(minutes: 5)
                }
                promptButton(title: "Dance") {
                    viewModel.convertToDance()
                }
                promptButton(title: "End") {
                    viewModel.showEndInteractionSheet = true
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }

    private func promptButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray4))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
