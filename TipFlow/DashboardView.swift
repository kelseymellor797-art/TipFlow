// DashboardView.swift — TipFlow
// Main shift dashboard: earnings summary, goal progress, interaction timer, quick-log buttons.

import SwiftUI
import UIKit

struct DashboardView: View {
    @Environment(ShiftStore.self) private var store
    @State private var showEndShift   = false
    @State private var showCustom     = false
    @State private var customType     = EarningsType.custom
    @State private var showGoalEditor = false
    @State private var showTipOut     = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        TotalEarningsCard(
                            amount: store.currentShift.totalEarnings,
                            goal:   store.nightlyGoal
                        )

                        HStack(spacing: 10) {
                            BreakdownCard(
                                title:    "Lap Dances",
                                amount:   store.currentShift.lapDanceTotal,
                                gradient: AppTheme.primaryGradient,
                                icon:     "sparkles"
                            )
                            BreakdownCard(
                                title:    "Stage Tips",
                                amount:   store.currentShift.stageTipTotal,
                                gradient: AppTheme.blueGradient,
                                icon:     "music.note"
                            )
                            BreakdownCard(
                                title:    "Random Tips",
                                amount:   store.currentShift.randomTipTotal,
                                gradient: AppTheme.tealGradient,
                                icon:     "dollarsign"
                            )
                        }

                        GoalProgressBar(
                            current: store.currentShift.totalEarnings,
                            goal:    store.nightlyGoal,
                            onEdit:  { showGoalEditor = true }
                        )

                        if store.isInteractionActive {
                            ActiveInteractionCard(elapsed: store.interactionElapsed) {
                                store.showEndInteractionSheet = true
                            }
                        } else {
                            StartInteractionButton { store.startInteraction() }
                        }

                        QuickLogGrid(showCustom: $showCustom, customType: $customType)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showTipOut = true
                    } label: {
                        Label("Tip Out", systemImage: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.neonPurple)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("TipFlow")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Shift") { showEndShift = true }
                        .foregroundStyle(AppTheme.neonPink)
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("End Shift?", isPresented: $showEndShift) {
            Button("End Shift", role: .destructive) { store.endShift() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your shift will be saved to history and a new one will begin.")
        }
        .sheet(isPresented: $showTipOut) {
            TipOutView()
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

            earningsGroup(title: "Lap Dances", gradient: AppTheme.primaryGradient, labelColor: AppTheme.neonPink) {
                QuickInputButton(label: "+$20", sublabel: "Lap Dance", gradient: AppTheme.primaryGradient) {
                    store.logEarnings(type: .lapDance, amount: 20)
                }
                QuickInputButton(label: "+$40", sublabel: "Lap Dance", gradient: AppTheme.primaryGradient) {
                    store.logEarnings(type: .lapDance, amount: 40)
                }
                customButton(gradient: AppTheme.primaryGradient, baseColor: AppTheme.neonPink, type: .lapDance)
            }

            earningsGroup(title: "Stage Tips", gradient: AppTheme.blueGradient, labelColor: AppTheme.neonBlue) {
                QuickInputButton(label: "+$5",  sublabel: "Stage Tip", gradient: AppTheme.blueGradient) {
                    store.logEarnings(type: .stageTip, amount: 5)
                }
                QuickInputButton(label: "+$10", sublabel: "Stage Tip", gradient: AppTheme.blueGradient) {
                    store.logEarnings(type: .stageTip, amount: 10)
                }
                customButton(gradient: AppTheme.blueGradient, baseColor: AppTheme.neonBlue, type: .stageTip)
            }

            earningsGroup(title: "Random Tips", gradient: AppTheme.tealGradient, labelColor: Color(red: 0.10, green: 0.85, blue: 0.80)) {
                QuickInputButton(label: "+$20", sublabel: "Random Tip", gradient: AppTheme.tealGradient) {
                    store.logEarnings(type: .randomTip, amount: 20)
                }
                customButton(gradient: AppTheme.tealGradient, baseColor: Color(red: 0.10, green: 0.85, blue: 0.80), type: .randomTip)
            }
        }
    }

    @ViewBuilder
    private func customButton(gradient: LinearGradient, baseColor: Color, type: EarningsType) -> some View {
        Button {
            customType = type
            showCustom = true
        } label: {
            VStack(spacing: 5) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(gradient)
                Text("Custom")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                ZStack {
                    AppTheme.cardBg
                    gradient.opacity(0.12)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(baseColor.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func earningsGroup<Content: View>(
        title: String,
        gradient: LinearGradient,
        labelColor: Color,
        @ViewBuilder buttons: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(labelColor)
            HStack(spacing: 10) {
                buttons()
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(ShiftStore())
}
