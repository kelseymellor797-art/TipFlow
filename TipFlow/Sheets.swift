// Sheets.swift — TipFlow
// Modal sheets and the 5-minute prompt overlay — synthwave neon theme.

import SwiftUI
import UIKit

// MARK: - OneMinutePromptOverlay

struct OneMinutePromptOverlay: View {
    @Environment(ShiftStore.self) private var store

    private var minutesElapsed: Int { Int(store.interactionElapsed) / 60 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.80)
                .ignoresSafeArea()
                .onTapGesture { store.dismissOneMinutePrompt() }

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.primaryGradient)
                        .symbolEffect(.pulse)

                    Text("Interaction at \(minutesElapsed) Minute\(minutesElapsed == 1 ? "" : "s")")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("What would you like to do?")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        PromptOptionButton(label: "+2 Minutes", icon: "plus.circle",
                                           gradient: AppTheme.blueGradient, baseColor: AppTheme.neonBlue) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.extendInteraction(by: 2)
                        }
                        PromptOptionButton(label: "+5 Minutes", icon: "plus.circle.fill",
                                           gradient: AppTheme.blueGradient, baseColor: AppTheme.neonBlue) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            store.extendInteraction(by: 5)
                        }
                    }

                    PromptOptionButton(
                        label: "Convert to Dance",
                        icon: "sparkles",
                        gradient: AppTheme.primaryGradient,
                        baseColor: AppTheme.neonPink
                    ) {
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
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(26)
            .background(
                ZStack {
                    AppTheme.cardBgElevated
                    RadialGradient(
                        colors: [AppTheme.neonPurple.opacity(0.18), .clear],
                        center: .center, startRadius: 10, endRadius: 200
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(AppTheme.borderGlow, lineWidth: 3.2)
            )
            .shadow(color: AppTheme.neonPurple.opacity(0.25), radius: 24, y: 8)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .center)))
    }
}

// MARK: - PromptOptionButton

struct PromptOptionButton: View {
    let label: String
    let icon: String
    let gradient: LinearGradient
    let baseColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(gradient)
                Text(label)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(baseColor.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(baseColor.opacity(0.40), lineWidth: 3.2)
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
                AppTheme.sheetBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Duration summary
                        VStack(spacing: 4) {
                            Text("Duration")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)
                                .kerning(1.2)
                            Text(formattedElapsed)
                                .font(.system(size: 46, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(AppTheme.cardBgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.borderGlow, lineWidth: 3)
                        )

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
                                        .foregroundStyle(AppTheme.textTertiary)
                                    TextField("0", text: $amountText)
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tint(AppTheme.neonPink)
                                        .focused($amountFocused)
                                }
                                .padding(16)
                                .background(AppTheme.cardBgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(AppTheme.neonPink.opacity(0.40), lineWidth: 3.2)
                                )
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
            .toolbarBackground(AppTheme.sheetBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commit() }
                        .font(.headline)
                        .foregroundStyle(AppTheme.neonPink)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: commit) {
                    Text("End Interaction")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.neonPink.opacity(0.35), radius: 10, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(AppTheme.sheetBg)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(AppTheme.sheetBg)
        .animation(.easeInOut(duration: 0.2), value: showAmountField)
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
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.neonPink : AppTheme.textTertiary)
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? AppTheme.neonPink.opacity(0.14) : AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(
                        isSelected ? AppTheme.neonPink.opacity(0.55) : AppTheme.borderSubtle,
                        lineWidth: 3.2
                    )
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

    var initialType: EarningsType = .custom

    @State private var amountText: String = ""
    @State private var selectedType: EarningsType = .custom
    @FocusState private var isFocused: Bool

    private var parsedAmount: Double? { Double(amountText) }
    private var isValid: Bool { (parsedAmount ?? 0) > 0 }
    private var accentColor: Color { AppTheme.color(for: selectedType) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.sheetBg.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Large amount display
                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, 6)
                        Text(amountText.isEmpty ? "0" : amountText)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.2), value: amountText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    // Hidden field drives keyboard
                    TextField("", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onAppear {
                            isFocused = true
                            selectedType = initialType
                        }

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
            .toolbarBackground(AppTheme.sheetBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
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
                        .background(isValid ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.cardBgElevated], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: isValid ? AppTheme.neonPink.opacity(0.35) : .clear, radius: 10, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(AppTheme.sheetBg)
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(AppTheme.sheetBg)
    }
}

// MARK: - CategoryChip

struct CategoryChip: View {
    let type: EarningsType
    let isSelected: Bool
    let action: () -> Void

    private var chipColor: Color { AppTheme.color(for: type) }

    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? chipColor.opacity(0.22) : AppTheme.cardBg)
                .foregroundStyle(isSelected ? chipColor : AppTheme.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? chipColor.opacity(0.60) : AppTheme.borderSubtle, lineWidth: 3.2)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - SetGoalSheet

struct SetGoalSheet: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var goalText: String = ""
    @FocusState private var isFocused: Bool

    private var parsedGoal: Double? { Double(goalText) }
    private var isValid: Bool { (parsedGoal ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.sheetBg.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Current goal
                    VStack(spacing: 6) {
                        Text("Current Goal")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textTertiary)
                            .textCase(.uppercase)
                            .kerning(1.2)
                        Text(store.nightlyGoal, format: .currency(code: "USD"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // New goal input
                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, 6)
                        Text(goalText.isEmpty ? "0" : goalText)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(isValid ? AppTheme.textPrimary : AppTheme.textTertiary)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.2), value: goalText)
                    }
                    .frame(maxWidth: .infinity)

                    TextField("", text: $goalText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onAppear {
                            isFocused = true
                            goalText = String(format: "%.0f", store.nightlyGoal)
                        }

                    // Quick-pick presets
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Quick Pick")
                        HStack(spacing: 8) {
                            ForEach([200, 300, 400, 500, 600], id: \.self) { preset in
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    goalText = "\(preset)"
                                } label: {
                                    Text("$\(preset)")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            goalText == "\(preset)"
                                                ? AppTheme.neonPink.opacity(0.20)
                                                : AppTheme.cardBg
                                        )
                                        .foregroundStyle(
                                            goalText == "\(preset)" ? AppTheme.neonPink : AppTheme.textSecondary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().strokeBorder(
                                                goalText == "\(preset)"
                                                    ? AppTheme.neonPink.opacity(0.55) : AppTheme.borderSubtle,
                                                lineWidth: 3.2
                                            )
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Nightly Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.sheetBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    guard let goal = parsedGoal, goal > 0 else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.updateGoal(goal)
                    dismiss()
                } label: {
                    Text(isValid
                         ? "Set Goal to \((parsedGoal ?? 0), format: .currency(code: "USD"))"
                         : "Enter an Amount")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isValid ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.cardBgElevated], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: isValid ? AppTheme.neonPink.opacity(0.35) : .clear, radius: 10, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(AppTheme.sheetBg)
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(AppTheme.sheetBg)
    }
}
