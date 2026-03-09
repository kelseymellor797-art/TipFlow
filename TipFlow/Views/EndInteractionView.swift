import SwiftUI

/// Sheet presented when ending an interaction to record outcome and earnings.
struct EndInteractionView: View {
    @EnvironmentObject var viewModel: ShiftViewModel
    @State private var selectedOutcome: InteractionOutcome = .noSale
    @State private var earningsText: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("End Interaction")
                    .font(.title2.bold())

                // Duration display
                if let interaction = viewModel.activeInteraction {
                    Text("Duration: \(ShiftViewModel.formatTime(Date().timeIntervalSince(interaction.startTime)))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                // Outcome selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Outcome")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(InteractionOutcome.allCases, id: \.self) { outcome in
                        outcomeButton(outcome)
                    }
                }

                // Earnings input (shown for outcomes that may have earnings)
                if selectedOutcome != .noSale {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount Earned")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("$")
                                .font(.title2)
                                .foregroundColor(.green)
                            TextField("0", text: $earningsText)
                                .font(.title2)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // Quick amount buttons
                        HStack(spacing: 8) {
                            amountButton("$20", amount: 20)
                            amountButton("$40", amount: 40)
                            amountButton("$60", amount: 60)
                            amountButton("$100", amount: 100)
                        }
                    }
                }

                Spacer()

                // Confirm button
                Button(action: confirmEnd) {
                    Text("Confirm")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
            }
            .padding()
            .navigationBarItems(
                trailing: Button("Cancel") {
                    viewModel.showEndInteractionSheet = false
                }
            )
        }
    }

    private func outcomeButton(_ outcome: InteractionOutcome) -> some View {
        Button(action: { selectedOutcome = outcome }) {
            HStack {
                Text(outcome.rawValue)
                    .font(.body)
                Spacer()
                if selectedOutcome == outcome {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .frame(height: 48)
            .background(selectedOutcome == outcome ? Color.green.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private func amountButton(_ label: String, amount: Double) -> some View {
        Button(action: { earningsText = String(Int(amount)) }) {
            Text(label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color(.systemGray5))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func confirmEnd() {
        let amount = Double(earningsText) ?? 0
        viewModel.endInteraction(outcome: selectedOutcome, earningsAmount: amount)
    }
}
