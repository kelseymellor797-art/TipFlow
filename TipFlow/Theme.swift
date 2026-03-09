// Theme.swift — TipFlow
// Synthwave color system inspired by the dark neon UI reference.

import SwiftUI

enum AppTheme {

    // MARK: - Backgrounds
    static let background        = Color(red: 0.07, green: 0.05, blue: 0.14) // #120D24
    static let cardBg            = Color(red: 0.11, green: 0.09, blue: 0.22) // #1C1738
    static let cardBgElevated    = Color(red: 0.15, green: 0.12, blue: 0.28) // #261E47
    static let sheetBg           = Color(red: 0.08, green: 0.06, blue: 0.16) // #141029

    // MARK: - Neon Accents
    static let neonPink          = Color(red: 1.00, green: 0.11, blue: 0.56) // #FF1C8F
    static let neonPurple        = Color(red: 0.55, green: 0.18, blue: 0.90) // #8C2EE6
    static let neonBlue          = Color(red: 0.24, green: 0.38, blue: 1.00) // #3D61FF
    static let neonViolet        = Color(red: 0.72, green: 0.25, blue: 1.00) // #B840FF

    // MARK: - Text
    static let textPrimary       = Color.white
    static let textSecondary     = Color.white.opacity(0.50)
    static let textTertiary      = Color.white.opacity(0.28)

    // MARK: - Borders / Glows
    static let borderGlow        = Color(red: 0.55, green: 0.18, blue: 0.90).opacity(0.35)
    static let borderSubtle      = Color.white.opacity(0.07)

    // MARK: - Gradients

    /// Hot magenta → deep violet  (primary / lap dances)
    static let primaryGradient = LinearGradient(
        colors: [neonPink, neonPurple],
        startPoint: .leading, endPoint: .trailing
    )

    /// Blue → violet  (stage tips)
    static let blueGradient = LinearGradient(
        colors: [neonBlue, neonViolet],
        startPoint: .leading, endPoint: .trailing
    )

    /// Teal-blue → blue  (random tips)
    static let tealGradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.75, blue: 0.86), neonBlue],
        startPoint: .leading, endPoint: .trailing
    )

    /// Full-spectrum progress bar
    static let progressGradient = LinearGradient(
        colors: [neonPink, neonPurple, neonBlue],
        startPoint: .leading, endPoint: .trailing
    )

    /// Goal-reached (gold)
    static let goldGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.80, blue: 0.20), Color(red: 1.0, green: 0.55, blue: 0.10)],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Per-category colors (for chips, labels, quick-pick buttons)
    static func color(for type: EarningsType) -> Color {
        switch type {
        case .lapDance:  return neonPink
        case .stageTip:  return neonBlue
        case .randomTip: return Color(red: 0.10, green: 0.85, blue: 0.80)  // cyan
        case .custom:    return neonViolet
        }
    }

    // MARK: - Glow card modifier helper
    static func glowCard(color: Color = AppTheme.borderGlow) -> some ShapeStyle {
        color
    }
}

// MARK: - View modifier for consistent card style

struct NeonCardModifier: ViewModifier {
    var glowColor: Color = AppTheme.borderGlow

    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(glowColor, lineWidth: 1)
            )
    }
}

extension View {
    func neonCard(glow: Color = AppTheme.borderGlow) -> some View {
        modifier(NeonCardModifier(glowColor: glow))
    }
}
