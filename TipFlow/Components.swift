// Components.swift — TipFlow
// Shared, reusable UI components — synthwave neon theme.

import SwiftUI
import UIKit

// MARK: - TotalEarningsCard

struct TotalEarningsCard: View {
    let amount: Double
    let goal: Double

    private var isGoalMet: Bool { amount >= goal }

    var body: some View {
        VStack(spacing: 8) {
            Text(isGoalMet ? "Goal Reached!" : "Tonight's Total")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isGoalMet ? Color(red:1,green:0.85,blue:0.2) : AppTheme.textSecondary)

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(.numericText(value: amount))
                .animation(.spring(duration: 0.4), value: amount)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            ZStack {
                AppTheme.cardBgElevated
                RadialGradient(
                    colors: [AppTheme.neonPurple.opacity(0.22), .clear],
                    center: .center, startRadius: 10, endRadius: 160
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    isGoalMet
                        ? Color(red:1,green:0.80,blue:0.2).opacity(0.45)
                        : AppTheme.borderGlow,
                    lineWidth: 3.2
                )
        )
    }
}

// MARK: - BreakdownCard

struct BreakdownCard: View {
    let title: String
    let amount: Double
    let gradient: LinearGradient
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(gradient)

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(.numericText(value: amount))
                .animation(.spring(duration: 0.3), value: amount)
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .neonCard()
    }
}

// MARK: - GoalProgressBar

struct GoalProgressBar: View {
    let current: Double
    let goal: Double
    var onEdit: (() -> Void)? = nil

    private var progress: Double  { min(current / max(goal, 1), 1.0) }
    private var percentage: Int   { Int(progress * 100) }
    private var remaining: Double { max(goal - current, 0) }
    private var isComplete: Bool  { current >= goal }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(isComplete ? "Goal Reached" : "Nightly Goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isComplete ? Color(red:1,green:0.85,blue:0.2) : AppTheme.textSecondary)
                Spacer()
                if !isComplete {
                    Text(remaining, format: .currency(code: "USD"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("to go")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
                }
                Text("\(percentage)%")
                    .font(.subheadline.bold())
                    .foregroundStyle(isComplete ? Color(red:1,green:0.85,blue:0.2) : AppTheme.textPrimary)
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 10)
                    Capsule()
                        .fill(isComplete ? AppTheme.goldGradient : AppTheme.progressGradient)
                        .frame(width: geo.size.width * CGFloat(progress), height: 10)
                        .animation(.spring(duration: 0.7, bounce: 0.2), value: progress)
                        .shadow(color: AppTheme.neonPink.opacity(0.55), radius: 6, y: 2)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .neonCard()
    }
}

// MARK: - GoalProjectionCard

struct GoalProjectionCard: View {
    let shift: Shift
    let goal: Double

    private func projectionInfo(elapsedHours: Double) -> (projected: Double, rate: Double, status: String, color: Color)? {
        guard elapsedHours >= 0.25 && shift.totalEarnings > 0 else { return nil }
        let rate = shift.totalEarnings / elapsedHours
        let projected = rate * shift.shiftDurationHours
        let ratio = projected / max(goal, 1)

        let status: String
        let color: Color
        if ratio >= 1.10 {
            status = "You're crushing it"
            color  = AppTheme.neonPink
        } else if ratio >= 0.90 {
            status = "On pace"
            color  = Color(red: 0.10, green: 0.85, blue: 0.80)
        } else if ratio >= 0.70 {
            status = "Pick up the pace"
            color  = Color(red: 1.0, green: 0.75, blue: 0.2)
        } else {
            status = "Time to hustle"
            color  = Color(red: 1.0, green: 0.45, blue: 0.35)
        }
        return (projected, rate, status, color)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let elapsedHours = context.date.timeIntervalSince(shift.startDate) / 3600
            if let info = projectionInfo(elapsedHours: elapsedHours) {
                VStack(spacing: 8) {
                    SectionHeader(title: "Goal Projection")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(info.projected, format: .currency(code: "USD"))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(info.color)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(info.status)
                        .font(.headline.bold())
                        .foregroundStyle(info.color)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Based on your \(info.rate.formatted(.currency(code: "USD")))/hr pace")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .neonCard()
            }
        }
    }
}

// MARK: - CirculationTrackerCard

struct CirculationTrackerCard: View {
    let lastEnd: Date

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(AppTheme.blueGradient)

            VStack(alignment: .leading, spacing: 4) {
                Text("Last Interaction")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(lastEnd, style: .relative)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("ago")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .neonCard(glow: AppTheme.neonBlue.opacity(0.20))
    }
}

// MARK: - NetProfitCard

struct NetProfitCard: View {
    let totalEarnings: Double
    let totalExpenses: Double

    var netProfit: Double { totalEarnings - totalExpenses }

    private var expenseRatio: Double { totalExpenses / max(totalEarnings, 1) }
    private var profitColor: Color {
        netProfit > 0 ? Color(red: 0.10, green: 0.85, blue: 0.80) : Color(red: 1.0, green: 0.45, blue: 0.35)
    }
    private var expenseColor: Color {
        expenseRatio > 0.3 ? Color(red: 1.0, green: 0.45, blue: 0.35) : AppTheme.textTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Profit")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Text(netProfit, format: .currency(code: "USD"))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(profitColor)
                .contentTransition(.numericText(value: netProfit))
                .animation(.spring(duration: 0.3), value: netProfit)

            Text("Expenses: \(totalExpenses.formatted(.currency(code: "USD")))")
                .font(.caption)
                .foregroundStyle(expenseColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .neonCard()
    }
}

// MARK: - QuickInputButton

struct QuickInputButton: View {
    let label: String
    let sublabel: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 5) {
                Text(label)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                ZStack {
                    AppTheme.cardBg
                    gradient.opacity(0.18)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(gradient.opacity(0.55), lineWidth: 3.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ActiveInteractionCard

struct ActiveInteractionCard: View {
    let elapsed: TimeInterval
    let onEnd: () -> Void

    private var formattedTime: String {
        let m = Int(elapsed) / 60
        let s = Int(elapsed) % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Interaction Active", systemImage: "person.fill.checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(formattedTime)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText(value: elapsed))
                    .animation(.linear(duration: 0.2), value: elapsed)
            }
            Spacer()
            Button(action: onEnd) {
                Text("End")
                    .font(.headline)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryGradient)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.neonPink.opacity(0.5), radius: 8, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .background(
            ZStack {
                AppTheme.cardBgElevated
                LinearGradient(
                    colors: [AppTheme.neonPurple.opacity(0.20), AppTheme.neonPink.opacity(0.10)],
                    startPoint: .leading, endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppTheme.neonPurple.opacity(0.45), lineWidth: 3.2)
        )
        .shadow(color: AppTheme.neonPurple.opacity(0.2), radius: 12, y: 4)
    }
}

// MARK: - StartInteractionButton

struct StartInteractionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Start Interaction", systemImage: "person.fill.checkmark")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(AppTheme.primaryGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppTheme.neonPink.opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.neonPurple.opacity(0.85))
            .textCase(.uppercase)
            .kerning(1.5)
    }
}

// MARK: - StatCard (Analytics)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(gradient)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .neonCard()
    }
}
