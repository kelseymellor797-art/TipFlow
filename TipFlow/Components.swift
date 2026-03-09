// Components.swift — TipFlow
// Shared, reusable UI components used across Dashboard and Analytics.

import SwiftUI
import UIKit

// MARK: - TotalEarningsCard

struct TotalEarningsCard: View {
    let amount: Double
    let goal: Double

    private var isGoalMet: Bool { amount >= goal }

    var body: some View {
        VStack(spacing: 6) {
            Text(isGoalMet ? "🎉 Goal Reached!" : "Tonight's Total")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: amount))
                .animation(.spring(duration: 0.4), value: amount)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: isGoalMet
                            ? [Color(white: 0.18), Color(white: 0.13)]
                            : [Color(white: 0.15), Color(white: 0.10)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            isGoalMet ? Color.yellow.opacity(0.4) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - BreakdownCard

struct BreakdownCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: amount))
                .animation(.spring(duration: 0.3), value: amount)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                Text(isComplete ? "Goal Reached 🎉" : "Nightly Goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isComplete ? Color.yellow : .white.opacity(0.65))
                Spacer()
                if !isComplete {
                    Text(remaining, format: .currency(code: "USD"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("to go")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
                Text("\(percentage)%")
                    .font(.subheadline.bold())
                    .foregroundStyle(isComplete ? .yellow : .white)
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isComplete ? [.yellow, .orange] : [.pink, .purple],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 10)
                        .animation(.spring(duration: 0.6, bounce: 0.2), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - QuickInputButton

struct QuickInputButton: View {
    let label: String
    let sublabel: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 5) {
                Text(label)
                    .font(.title2.bold())
                Text(sublabel)
                    .font(.caption)
                    .opacity(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(color.opacity(0.18))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(0.45), lineWidth: 1.5)
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
                    .foregroundStyle(.white.opacity(0.55))

                Text(formattedTime)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: elapsed))
                    .animation(.linear(duration: 0.2), value: elapsed)
            }

            Spacer()

            Button(action: onEnd) {
                Text("End")
                    .font(.headline)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(Color.pink)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.28), Color.pink.opacity(0.18)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.purple.opacity(0.4), lineWidth: 1)
        )
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
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.4))
            .textCase(.uppercase)
            .kerning(1.2)
    }
}

// MARK: - StatCard (Analytics)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
