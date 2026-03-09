// TipOutView.swift — TipFlow
// End-of-shift tip-out calculator. Manager & DJ fixed at 10%; Bouncer customizable.

import SwiftUI
import UIKit

struct TipOutView: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var overrideTotal: Double? = nil

    @State private var bouncerExpanded = false

    private var total: Double { overrideTotal ?? store.currentShift.totalEarnings }

    private struct FixedRecipient {
        let role: String
        let icon: String
        let rate: Double
        let gradient: LinearGradient
    }

    private let fixedRecipients: [FixedRecipient] = [
        FixedRecipient(role: "Manager", icon: "person.badge.shield.checkmark", rate: 0.10, gradient: AppTheme.primaryGradient),
        FixedRecipient(role: "DJ",      icon: "music.note",                    rate: 0.10, gradient: AppTheme.blueGradient),
    ]

    private var totalTipOut: Double {
        fixedRecipients.reduce(0) { $0 + total * $1.rate } + total * store.bouncerRate
    }
    private var takeHome: Double { total - totalTipOut }

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
                                .strokeBorder(AppTheme.borderGlow, lineWidth: 1)
                        )

                        // ── Tip out rows ──────────────────────────────────
                        SectionHeader(title: "Tip Out")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            // Fixed rows
                            ForEach(fixedRecipients, id: \.role) { r in
                                TipOutRow(
                                    role:     r.role,
                                    icon:     r.icon,
                                    rate:     r.rate,
                                    amount:   total * r.rate,
                                    gradient: r.gradient
                                )
                            }

                            // Bouncer — editable
                            BouncerRow(
                                rate:        store.bouncerRate,
                                amount:      total * store.bouncerRate,
                                isExpanded:  $bouncerExpanded
                            ) { newRate in
                                store.updateBouncerRate(newRate)
                            }
                        }

                        // ── Summary ───────────────────────────────────────
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(AppTheme.borderGlow)
                                .frame(height: 1)
                                .padding(.horizontal, 4)

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
                                    .strokeBorder(AppTheme.neonPink.opacity(0.30), lineWidth: 1)
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
                                .strokeBorder(AppTheme.neonPurple.opacity(0.50), lineWidth: 1.2)
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
}

// MARK: - TipOutRow (fixed)

private struct TipOutRow: View {
    let role:     String
    let icon:     String
    let rate:     Double
    let amount:   Double
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(gradient)
                .frame(width: 44, height: 44)
                .background(AppTheme.cardBgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(gradient.opacity(0.45), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(role)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(Int(rate * 100))% of total")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - BouncerRow (editable)

private struct BouncerRow: View {
    let rate:       Double
    let amount:     Double
    @Binding var isExpanded: Bool
    let onSelect:   (Double) -> Void

    private let presets: [Double] = [0, 0.03, 0.05, 0.08, 0.10, 0.15]

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button { 
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "figure.stand")
                        .font(.title3)
                        .foregroundStyle(AppTheme.tealGradient)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.cardBgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(AppTheme.tealGradient.opacity(0.45), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bouncer / Doorman")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        HStack(spacing: 4) {
                            Text("\(Int(rate * 100))% of total")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.neonViolet.opacity(0.7))
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

            // Expanded preset chips
            if isExpanded {
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(AppTheme.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                onSelect(preset)
                                withAnimation(.spring(duration: 0.2)) { isExpanded = false }
                            } label: {
                                Text(preset == 0 ? "None" : "\(Int(preset * 100))%")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        rate == preset
                                            ? AppTheme.neonViolet.opacity(0.22)
                                            : AppTheme.cardBgElevated
                                    )
                                    .foregroundStyle(
                                        rate == preset ? AppTheme.neonViolet : AppTheme.textSecondary
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(
                                            rate == preset
                                                ? AppTheme.neonViolet.opacity(0.55)
                                                : AppTheme.borderSubtle,
                                            lineWidth: 1.2
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
                    isExpanded ? AppTheme.neonViolet.opacity(0.45) : AppTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .animation(.spring(duration: 0.3), value: isExpanded)
    }
}

#Preview {
    TipOutView()
        .environment(ShiftStore())
}
