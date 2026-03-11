// DashboardView.swift — TipFlow
// Main shift dashboard: earnings summary, goal progress, interaction timer, quick-log buttons.

import SwiftUI
import UIKit

// Single enum drives every sheet presented from the Dashboard
enum DashboardSheet: Identifiable, Equatable {
    case tipOut
    case expenses
    case custom(EarningsType)
    case goalEditor
    case endInteraction
    case startShift

    var id: String {
        switch self {
        case .tipOut:               "tipOut"
        case .expenses:             "expenses"
        case .custom(let t):        "custom.\(t)"
        case .goalEditor:           "goalEditor"
        case .endInteraction:       "endInteraction"
        case .startShift:           "startShift"
        }
    }
}

struct DashboardView: View {
    @Environment(ShiftStore.self) private var store
    @State private var showEndShift  = false
    @State private var activeSheet: DashboardSheet?

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
                            onEdit:  { activeSheet = .goalEditor }
                        )

                        if store.currentShift.totalEarnings > 0 {
                            GoalProjectionCard(shift: store.currentShift, goal: store.nightlyGoal)
                        }

                        if store.isInteractionActive {
                            ActiveInteractionCard(elapsed: store.interactionElapsed) {
                                store.showEndInteractionSheet = true
                            }
                        } else {
                            StartInteractionButton { store.startInteraction() }
                            if let lastEnd = store.lastInteractionEndTime {
                                CirculationTrackerCard(lastEnd: lastEnd)
                            }
                        }

                        QuickLogGrid(activeSheet: $activeSheet)

                        if !store.currentShift.expenses.isEmpty {
                            NetProfitCard(
                                totalEarnings: store.currentShift.totalEarnings,
                                totalExpenses: store.currentShift.totalExpenses
                            )
                        }
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
                    Menu {
                        Button {
                            activeSheet = .tipOut
                        } label: {
                            Label("Tip Out", systemImage: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                        Button {
                            activeSheet = .expenses
                        } label: {
                            Label("Add Expense", systemImage: "minus.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
        // ONE sheet to rule them all
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .tipOut:
                TipOutView()
            case .expenses:
                AddExpenseSheet()
            case .custom(let type):
                CustomAmountSheet(initialType: type)
            case .goalEditor:
                SetGoalSheet()
            case .endInteraction:
                EndInteractionSheet()
            case .startShift:
                OutfitSetupSheet(mode: .startShift)
            }
        }
        // Sync store booleans → single sheet
        .onChange(of: store.showEndInteractionSheet) { _, show in
            if show {
                activeSheet = .endInteraction
            } else if case .endInteraction = activeSheet {
                activeSheet = nil
            }
        }
        .onChange(of: store.showStartShift) { _, show in
            if show {
                activeSheet = .startShift
            } else if case .startShift = activeSheet {
                activeSheet = nil
            }
        }
        // Sync sheet dismiss → store booleans
        .onChange(of: activeSheet) { _, sheet in
            if sheet == nil, store.showEndInteractionSheet {
                store.showEndInteractionSheet = false
            }
        }
        .alert("End Shift?", isPresented: $showEndShift) {
            Button("End Shift", role: .destructive) { store.endShift() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your shift will be saved to history and a new one will begin.")
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
    @Binding var activeSheet: DashboardSheet?

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
            activeSheet = .custom(type)
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
                    .strokeBorder(baseColor.opacity(0.35), lineWidth: 3.5)
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
