// Sheets.swift — TipFlow
// Modal sheets and the one-minute prompt overlay.

import SwiftUI
import UIKit

// MARK: - OneMinutePromptOverlay

struct OneMinutePromptOverlay: View {
    @Environment(ShiftStore.self) private var store

    private var minutesElapsed: Int { Int(store.interactionElapsed) / 60 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { store.dismissOneMinutePrompt() }

            VStack(spacing: 22) {
                // Icon + headline
                VStack(spacing: 10) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.pulse)

                    Text("Interaction at \(minutesElapsed) Minute\(minutesElapsed == 1 ? "" : "s")")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("What would you like to do?")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }

                // Action buttons
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        PromptOptionButton(label: "+2 Minutes", icon: "plus.circle", color: .blue) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.extendInteraction(by: 2)
                        }
                        PromptOptionButton(label: "+5 Minutes", icon: "plus.circle.fill", color: .blue) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.extendInteraction(by: 5)
                        }
                    }

                    PromptOptionButton(label: "Convert to Dance  💃", icon: "sparkles", color: .pink) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        store.endInteraction(outcome: .oneDance, amount: 20)
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        store.showOneMinutePrompt = false
                        store.showEndInteractionSheet = true
                    } label: {
                        Text("End Interaction")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.top, 4)
                    }
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(white: 0.11))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .center)))
    }
}

// MARK: - PromptOptionButton

struct PromptOptionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(label).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - EndInteractionSheet

struct EndInteractionSheet: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOutcome: InteractionOutcome = .noSale
    @State private var amountText: String = ""
    @FocusState private var amountFocused: Bool

    private var showAmountField: Bool { selectedOutcome != .noSale }

    private var formattedElapsed: String {
        let m = Int(store.interactionElapsed) / 60
        let s = Int(store.interactionElapsed) % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Duration summary
                        VStack(spacing: 4) {
                            Text("Duration")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.45))
                                .textCase(.uppercase)
                                .kerning(1)

                            Text(formattedElapsed)
                                .font(.system(size: 44, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(white: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Outcome picker
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Outcome")

                            VStack(spacing: 8) {
                                ForEach(InteractionOutcome.allCases, id: \.self) { outcome in
                                    OutcomeRow(outcome: outcome, isSelected: selectedOutcome == outcome) {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        selectedOutcome = outcome
                                        amountText = outcome != .noSale
                                            ? String(format: "%.0f", outcome.earningsSuggestion)
                                            : ""
                                    }
                                }
                            }
                        }

                        // Amount input
                        if showAmountField {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(title: "Amount Earned")

                                HStack(spacing: 8) {
                                    Text("$")
                                        .font(.title.bold())
                                        .foregroundStyle(.white.opacity(0.5))

                                    TextField("0", text: $amountText)
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(.white)
                                        .tint(.pink)
                                        .focused($amountFocused)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onAppear { amountFocused = true }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("End Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.55))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commit() }
                        .font(.headline)
                        .foregroundStyle(.pink)
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(.ultraThinMaterial)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.black)
        .animation(.easeInOut(duration: 0.2), value: showAmountField)
    }

    private var confirmButton: some View {
        Button(action: commit) {
            Text("End Interaction")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.pink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func commit() {
        let amount = Double(amountText)
        store.endInteraction(outcome: selectedOutcome, amount: amount)
        dismiss()
    }
}

// MARK: - OutcomeRow

struct OutcomeRow: View {
    let outcome: InteractionOutcome
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(outcome.emoji)
                    .font(.title3)
                Text(outcome.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .pink : .white.opacity(0.25))
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.pink.opacity(0.18) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(isSelected ? Color.pink.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - CustomAmountSheet

struct CustomAmountSheet: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = ""
    @State private var selectedType: EarningsType = .custom
    @FocusState private var isFocused: Bool

    private var parsedAmount: Double? { Double(amountText) }
    private var isValid: Bool { (parsedAmount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Large amount display
                    VStack(spacing: 2) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("$")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(.white.opacity(0.35))
                                .padding(.top, 6)

                            Text(amountText.isEmpty ? "0" : amountText)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.2), value: amountText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    // Hidden field drives the keyboard
                    TextField("", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onAppear { isFocused = true }

                    // Category chips
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Category")

                        HStack(spacing: 8) {
                            ForEach(EarningsType.allCases, id: \.self) { type in
                                CategoryChip(type: type, isSelected: selectedType == type) {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    selectedType = type
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    guard let amt = parsedAmount, amt > 0 else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.logEarnings(type: selectedType, amount: amt)
                    dismiss()
                } label: {
                    Text(isValid
                        ? "Add \((parsedAmount ?? 0), format: .currency(code: "USD"))"
                        : "Enter an Amount")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isValid ? Color.pink : Color.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(.ultraThinMaterial)
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.black)
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {
    let type: EarningsType
    let isSelected: Bool
    let action: () -> Void

    private var chipColor: Color {
        switch type {
        case .lapDance:  return .pink
        case .stageTip:  return .purple
        case .randomTip: return .teal
        case .custom:    return .orange
        }
    }

    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? chipColor.opacity(0.28) : Color.white.opacity(0.08))
                .foregroundStyle(isSelected ? chipColor : .white.opacity(0.55))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? chipColor.opacity(0.55) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
