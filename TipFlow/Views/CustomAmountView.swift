import SwiftUI

/// Sheet for entering a custom earnings amount with category selection.
struct CustomAmountView: View {
    @EnvironmentObject var viewModel: ShiftViewModel
    @State private var amountText: String = ""
    @State private var selectedCategory: EarningCategory = .custom

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Custom Amount")
                    .font(.title2.bold())

                // Amount input
                HStack {
                    Text("$")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                    TextField("0", text: $amountText)
                        .font(.system(size: 40, weight: .bold))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Quick amounts
                HStack(spacing: 12) {
                    quickAmountButton("$10", amount: 10)
                    quickAmountButton("$25", amount: 25)
                    quickAmountButton("$50", amount: 50)
                    quickAmountButton("$100", amount: 100)
                }

                // Category selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(EarningCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }

                Spacer()

                // Add button
                Button(action: addCustomAmount) {
                    Text("Add")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(amountText.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
                .disabled(amountText.isEmpty)
            }
            .padding()
            .navigationBarItems(
                trailing: Button("Cancel") {
                    viewModel.showCustomAmountSheet = false
                }
            )
        }
    }

    private func quickAmountButton(_ label: String, amount: Int) -> some View {
        Button(action: { amountText = "\(amount)" }) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(.systemGray5))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    private func categoryButton(_ category: EarningCategory) -> some View {
        Button(action: { selectedCategory = category }) {
            HStack {
                Text(category.rawValue)
                    .font(.body)
                Spacer()
                if selectedCategory == category {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .frame(height: 44)
            .background(selectedCategory == category ? Color.green.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    private func addCustomAmount() {
        guard let amount = Double(amountText), amount > 0 else { return }
        viewModel.addEarning(amount: amount, category: selectedCategory)
        viewModel.showCustomAmountSheet = false
    }
}
