// TipOutView.swift — TipFlow
// End-of-shift tip-out calculator. All rates customizable, amounts rounded up.

import SwiftUI
import UIKit

// Rounds down at .50, up only when fraction > .50 (e.g. 13.50 → 13, 13.51 → 14)
private func roundTipOut(_ value: Double) -> Double {
    let fraction = value - floor(value)
    return fraction > 0.5 ? ceil(value) : floor(value)
}

struct TipOutView: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var overrideTotal: Double? = nil

    @State private var expandedRole: String? = nil

    private var total: Double { overrideTotal ?? store.currentShift.totalEarnings }

    private var managerAmount: Double { roundTipOut(total * store.managerRate) }
    private var djAmount:      Double { roundTipOut(total * store.djRate) }
    private var bouncerAmount: Double { roundTipOut(total * store.bouncerRate) }
    private var totalTipOut:   Double { managerAmount + djAmount + bouncerAmount }
    private var takeHome:      Double { max(0, total - totalTipOut) }

    private let presets: [Double] = [0, 0.03, 0.05, 0.08, 0.10, 0.15, 0.20]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.sheetBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Shift total ───────────────────────────────────
                        VStack(spacing: 6) {
                            Text("Shift Total")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)
                                .kerning(1.2)
                            Text(total, format: .currency(code: "USD"))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(AppTheme.cardBgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(AppTheme.borderGlow, lineWidth: 3)
                        )

                        // ── Tip out rows ──────────────────────────────────
                        SectionHeader(title: "Tip Out  —  tap to edit %")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            EditableRateRow(
                                role:        "Manager",
                                icon:        "person.badge.shield.checkmark",
                                rate:        store.managerRate,
                                amount:      managerAmount,
                                gradient:    AppTheme.primaryGradient,
                                accentColor: AppTheme.neonPink,
                                presets:     presets,
                                isExpanded:  expandedRole == "Manager"
                            ) {
                                toggle("Manager")
                            } onSelect: { rate in
                                store.updateManagerRate(rate)
                                expandedRole = nil
                            }

                            EditableRateRow(
                                role:        "DJ",
                                icon:        "music.note",
                                rate:        store.djRate,
                                amount:      djAmount,
                                gradient:    AppTheme.blueGradient,
                                accentColor: AppTheme.neonBlue,
                                presets:     presets,
                                isExpanded:  expandedRole == "DJ"
                            ) {
                                toggle("DJ")
                            } onSelect: { rate in
                                store.updateDJRate(rate)
                                expandedRole = nil
                            }

                            EditableRateRow(
                                role:        "Bouncer / Doorman",
                                icon:        "figure.stand",
                                rate:        store.bouncerRate,
                                amount:      bouncerAmount,
                                gradient:    AppTheme.tealGradient,
                                accentColor: AppTheme.neonViolet,
                                presets:     presets,
                                isExpanded:  expandedRole == "Bouncer / Doorman"
                            ) {
                                toggle("Bouncer / Doorman")
                            } onSelect: { rate in
                                store.updateBouncerRate(rate)
                                expandedRole = nil
                            }
                        }

                        // ── Summary ───────────────────────────────────────
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(AppTheme.borderGlow)
                                .frame(height: 1)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Tip-Out")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    Text(totalTipOut, format: .currency(code: "USD"))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.neonPink)
                                        .contentTransition(.numericText(value: totalTipOut))
                                        .animation(.spring(duration: 0.3), value: totalTipOut)
                                }
                                Spacer()
                                Text("\(Int((totalTipOut / max(total, 1)) * 100))% of earnings")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .padding(18)
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.neonPink.opacity(0.30), lineWidth: 3)
                            )
                        }

                        // ── Take-home ─────────────────────────────────────
                        VStack(spacing: 6) {
                            Text("You Take Home")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)
                                .kerning(1.2)
                            Text(takeHome, format: .currency(code: "USD"))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .contentTransition(.numericText(value: takeHome))
                                .animation(.spring(duration: 0.3), value: takeHome)
                                .shadow(color: AppTheme.neonPurple.opacity(0.55), radius: 12, y: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(
                            ZStack {
                                AppTheme.cardBgElevated
                                RadialGradient(
                                    colors: [AppTheme.neonPurple.opacity(0.20), .clear],
                                    center: .center, startRadius: 10, endRadius: 180
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(AppTheme.neonPurple.opacity(0.50), lineWidth: 3.2)
                        )
                        .shadow(color: AppTheme.neonPurple.opacity(0.20), radius: 16, y: 6)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Tip Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.sheetBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(AppTheme.neonPink)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(AppTheme.sheetBg)
    }

    private func toggle(_ role: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(duration: 0.3)) {
            expandedRole = expandedRole == role ? nil : role
        }
    }
}

// MARK: - EditableRateRow

private struct EditableRateRow: View {
    let role:        String
    let icon:        String
    let rate:        Double
    let amount:      Double
    let gradient:    LinearGradient
    let accentColor: Color
    let presets:     [Double]
    let isExpanded:  Bool
    let onTap:       () -> Void
    let onSelect:    (Double) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(gradient)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.cardBgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(gradient.opacity(0.45), lineWidth: 3)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(role)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        HStack(spacing: 4) {
                            Text(rate == 0 ? "Not tipping" : "\(Int(rate * 100))% of total")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundStyle(accentColor.opacity(0.65))
                        }
                    }

                    Spacer()

                    Text(amount, format: .currency(code: "USD"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText(value: amount))
                        .animation(.spring(duration: 0.3), value: amount)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Preset chips
            if isExpanded {
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(AppTheme.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    HStack(spacing: 6) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSelect(preset)
                            } label: {
                                Text(preset == 0 ? "None" : "\(Int(preset * 100))%")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        rate == preset
                                            ? accentColor.opacity(0.22)
                                            : AppTheme.cardBgElevated
                                    )
                                    .foregroundStyle(
                                        rate == preset ? accentColor : AppTheme.textSecondary
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(
                                            rate == preset
                                                ? accentColor.opacity(0.55)
                                                : AppTheme.borderSubtle,
                                            lineWidth: 3.2
                                        )
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isExpanded ? accentColor.opacity(0.40) : AppTheme.borderSubtle,
                    lineWidth: 3
                )
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    TipOutView()
        .environment(ShiftStore())
}
