// DashboardView.swift — TipFlow
// Main shift dashboard: earnings summary, goal progress, interaction timer, quick-log buttons.

import SwiftUI
import UIKit

struct DashboardView: View {
    @Environment(ShiftStore.self) private var store
    @State private var showEndShift    = false
    @State private var showCustom      = false
    @State private var customType      = EarningsType.custom
    @State private var showGoalEditor  = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // ── Earnings summary ──────────────────────────────
                        TotalEarningsCard(
                            amount: store.currentShift.totalEarnings,
                            goal:   store.nightlyGoal
                        )

                        HStack(spacing: 10) {
                            BreakdownCard(
                                title: "Lap Dances",
                                amount: store.currentShift.lapDanceTotal,
                                color: .pink, icon: "sparkles"
                            )
                            BreakdownCard(
                                title: "Stage Tips",
                                amount: store.currentShift.stageTipTotal,
                                color: .purple, icon: "music.note"
                            )
                            BreakdownCard(
                                title: "Random Tips",
                                amount: store.currentShift.randomTipTotal,
                                color: .teal, icon: "dollarsign"
                            )
                        }

                        // ── Goal progress ─────────────────────────────────
                        GoalProgressBar(
                            current: store.currentShift.totalEarnings,
                            goal:    store.nightlyGoal,
                            onEdit:  { showGoalEditor = true }
                        )

                        // ── Interaction ───────────────────────────────────
                        if store.isInteractionActive {
                            ActiveInteractionCard(elapsed: store.interactionElapsed) {
                                store.showEndInteractionSheet = true
                            }
                        } else {
                            StartInteractionButton { store.startInteraction() }
                        }

                        // ── Quick log ─────────────────────────────────────
                        QuickLogGrid(showCustom: $showCustom, customType: $customType)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TipFlow")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Shift") { showEndShift = true }
                        .foregroundStyle(.pink)
                        .fontWeight(.semibold)
                }
            }
        }
        // ── Alerts & sheets ───────────────────────────────────────────────
        .alert("End Shift?", isPresented: $showEndShift) {
            Button("End Shift", role: .destructive) { store.endShift() }
            Button("Cancel",    role: .cancel) {}
        } message: {
            Text("Your shift will be saved to history and a new one will begin.")
        }
        .sheet(isPresented: $showCustom) {
            CustomAmountSheet(initialType: customType)
        }
        .sheet(isPresented: $showGoalEditor) {
            SetGoalSheet()
        }
        .sheet(isPresented: $store.showEndInteractionSheet) {
            EndInteractionSheet()
        }
        // 1-minute prompt floats above everything
        .overlay {
            if store.showOneMinutePrompt {
                OneMinutePromptOverlay()
                    .zIndex(10)
            }
        }
        .animation(.spring(duration: 0.3), value: store.showOneMinutePrompt)
    }
}

// MARK: - QuickLogGrid

private struct QuickLogGrid: View {
    @Environment(ShiftStore.self) private var store
    @Binding var showCustom: Bool
    @Binding var customType: EarningsType

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Quick Log")
                .padding(.top, 4)

            // Lap Dances
            earningsGroup(title: "Lap Dances", color: .pink) {
                QuickInputButton(label: "+$20", sublabel: "Lap Dance", color: .pink) {
                    store.logEarnings(type: .lapDance, amount: 20)
                }
                QuickInputButton(label: "+$40", sublabel: "Lap Dance", color: .pink) {
                    store.logEarnings(type: .lapDance, amount: 40)
                }
                customButton(color: .pink, type: .lapDance)
            }

            // Stage Tips
            earningsGroup(title: "Stage Tips", color: .purple) {
                QuickInputButton(label: "+$5",  sublabel: "Stage Tip", color: .purple) {
                    store.logEarnings(type: .stageTip, amount: 5)
                }
                QuickInputButton(label: "+$10", sublabel: "Stage Tip", color: .purple) {
                    store.logEarnings(type: .stageTip, amount: 10)
                }
                customButton(color: .purple, type: .stageTip)
            }

            // Random Tips + Custom
            earningsGroup(title: "Random Tips", color: .teal) {
                QuickInputButton(label: "+$20", sublabel: "Random Tip", color: .teal) {
                    store.logEarnings(type: .randomTip, amount: 20)
                }
                customButton(color: .teal, type: .randomTip)
            }
        }
    }

    @ViewBuilder
    private func customButton(color: Color, type: EarningsType) -> some View {
        Button {
            customType = type
            showCustom = true
        } label: {
            VStack(spacing: 5) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                Text("Custom")
                    .font(.subheadline.bold())
                Text("Amount")
                    .font(.caption)
                    .opacity(0.6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(color.opacity(0.10))
            .foregroundStyle(color.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(0.30), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
        }
    }

    @ViewBuilder
    private func earningsGroup<Content: View>(
        title: String,
        color: Color,
        @ViewBuilder buttons: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color.opacity(0.85))

            HStack(spacing: 10) {
                buttons()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(ShiftStore())
}
