// TipOutView.swift — TipFlow
// End-of-shift tip-out calculator. 10% each to Manager, DJ, Bouncer.

import SwiftUI
import UIKit

struct TipOutView: View {
    @Environment(ShiftStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Allow override for a custom total (e.g. if ending mid-shift with a specific amount)
    var overrideTotal: Double? = nil

    private var total: Double { overrideTotal ?? store.currentShift.totalEarnings }

    private struct Recipient {
        let role: String
        let icon: String
        let rate: Double      // 0.0 – 1.0
        let gradient: LinearGradient
    }

    private let recipients: [Recipient] = [
        Recipient(role: "Manager",         icon: "person.badge.shield.checkmark", rate: 0.10, gradient: AppTheme.primaryGradient),
        Recipient(role: "DJ",              icon: "music.note",                     rate: 0.10, gradient: AppTheme.blueGradient),
        Recipient(role: "Bouncer",         icon: "figure.stand",                   rate: 0.05, gradient: AppTheme.tealGradient),
    ]

    private var totalTipOut: Double { recipients.reduce(0) { $0 + (total * $1.rate) } }
    private var takeHome: Double    { total - totalTipOut }

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
                        SectionHeader(title: "Tip Out (10% each)")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            ForEach(recipients, id: \.role) { r in
                                TipOutRow(
                                    role:     r.role,
                                    icon:     r.icon,
                                    rate:     r.rate,
                                    amount:   total * r.rate,
                                    gradient: r.gradient
                                )
                            }
                        }

                        // ── Divider + summary ─────────────────────────────
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
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(Int(totalTipOut / max(total, 1) * 100))% of earnings")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                    Text("(\(Int(totalTipOut / max(total, 1) * 100))%)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
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

// MARK: - TipOutRow

private struct TipOutRow: View {
    let role:     String
    let icon:     String
    let rate:     Double
    let amount:   Double
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 14) {
            // Icon badge
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

#Preview {
    TipOutView()
        .environment(ShiftStore())
}
