// OutfitView.swift — TipFlow
// Dedicated outfit tracking tab: current outfit, tonight's timeline, all-time analytics.

import SwiftUI

struct OutfitView: View {
    @Environment(ShiftStore.self) private var store
    @State private var showChangeOutfit = false
    @State private var showStartShift   = false

    private var shift: Shift { store.currentShift }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Section 1: Current Outfit
                        if shift.isStarted {
                            if let active = shift.activeOutfitSession {
                                CurrentOutfitCard(
                                    session: active,
                                    earnings: shift.earningsForOutfit(active),
                                    dances: shift.danceCountForOutfit(active),
                                    store: store
                                ) { showChangeOutfit = true }
                            } else {
                                startNewOutfitBanner { showChangeOutfit = true }
                            }
                        } else {
                            StartShiftPromptCard { showStartShift = true }
                        }

                        // Section 2: Tonight's timeline
                        if !shift.outfitSessions.isEmpty {
                            ShiftOutfitTimeline(shift: shift)
                        }

                        // Section 3: All-time analytics
                        let allSessions = store.pastShifts.flatMap { $0.outfitSessions }
                            + shift.outfitSessions.filter { !$0.isActive }
                        if !allSessions.isEmpty {
                            OutfitAnalyticsSection(sessions: allSessions)
                        }

                        if !shift.isStarted && store.pastShifts.isEmpty {
                            emptyStateView
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
                ToolbarItem(placement: .principal) {
                    Text("Outfits")
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showChangeOutfit) {
            OutfitSetupSheet(mode: .changeOutfit)
        }
        .sheet(isPresented: $showStartShift) {
            OutfitSetupSheet(mode: .startShift)
        }
    }

    @ViewBuilder
    private func startNewOutfitBanner(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Log New Outfit", systemImage: "tshirt.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primaryGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "tshirt")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.textTertiary)
            Text("No outfit data yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Start a shift and log your outfit\nto track what earns the most.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - StartShiftPromptCard

private struct StartShiftPromptCard: View {
    let action: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primaryGradient)
            Text("Ready to start?")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Log your outfit to track which look earns the most.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: action) {
                Text("Start Shift + Log Outfit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primaryGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(24)
        .neonCard(glow: AppTheme.neonPurple.opacity(0.35))
    }
}

// MARK: - CurrentOutfitCard

private struct CurrentOutfitCard: View {
    let session: OutfitSession
    let earnings: Double
    let dances: Int
    let store: ShiftStore
    let onChangeOutfit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Photo or placeholder
            ZStack {
                if let filename = session.photoFilename,
                   let img = store.loadOutfitPhoto(filename: filename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppTheme.neonPurple.opacity(0.25), AppTheme.neonPink.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(AppTheme.neonPurple.opacity(0.5))
                        )
                }
                // "Active" badge
                VStack {
                    HStack {
                        Spacer()
                        Text("Active")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.neonPink)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // Details
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.name.isEmpty ? "Current Outfit" : session.name)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        HStack(spacing: 6) {
                            if let style = session.style {
                                tagChip(style.rawValue, color: AppTheme.neonPurple)
                            }
                            if let finish = session.fabricFinish {
                                tagChip(finish.rawValue, color: AppTheme.neonBlue)
                            }
                            if !session.primaryColor.isEmpty {
                                tagChip(session.primaryColor, color: AppTheme.neonPink.opacity(0.7))
                            }
                        }
                    }
                    Spacer()
                    if session.confidenceRating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= session.confidenceRating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(i <= session.confidenceRating
                                        ? Color(red: 1, green: 0.85, blue: 0.2)
                                        : AppTheme.textTertiary)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    statBubble(label: "Earned", value: earnings.formatted(.currency(code: "USD")), color: AppTheme.neonPink)
                    statBubble(label: "Dances", value: "\(dances)", color: AppTheme.neonPurple)
                    statBubble(label: "Active", value: timerText, color: AppTheme.neonBlue)
                }

                Button(action: onChangeOutfit) {
                    Label("Change Outfit", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(16)
        }
        .background(AppTheme.cardBgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AppTheme.borderGlow, lineWidth: 3))
        .shadow(color: AppTheme.neonPurple.opacity(0.2), radius: 12, y: 4)
    }

    private var timerText: String {
        let d = Int(session.duration)
        let h = d / 3600; let m = (d % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    @ViewBuilder
    private func tagChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func statBubble(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - ShiftOutfitTimeline

private struct ShiftOutfitTimeline: View {
    let shift: Shift

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tonight's Outfits")
            ForEach(shift.outfitSessions) { session in
                timelineRow(
                    session: session,
                    earnings: shift.earningsForOutfit(session),
                    dances: shift.danceCountForOutfit(session)
                )
            }
        }
        .padding(16)
        .neonCard()
    }

    @ViewBuilder
    private func timelineRow(session: OutfitSession, earnings: Double, dances: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(session.isActive ? AppTheme.neonPink : AppTheme.neonPurple.opacity(0.6))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.name.isEmpty ? "Outfit \(outfitNumber(session))" : session.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if session.isActive {
                        Text("Active")
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(AppTheme.neonPink.opacity(0.2))
                            .foregroundStyle(AppTheme.neonPink)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text(earnings, format: .currency(code: "USD"))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                }
                HStack(spacing: 6) {
                    Text(timeRange(session))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("·")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    if dances > 0 {
                        Text("·")
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(dances) dance\(dances == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
    }

    private func outfitNumber(_ session: OutfitSession) -> Int {
        (shift.outfitSessions.firstIndex(where: { $0.id == session.id }) ?? 0) + 1
    }

    private func timeRange(_ session: OutfitSession) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        let start = fmt.string(from: session.startTime)
        if let end = session.endTime {
            return "\(start) – \(fmt.string(from: end))"
        }
        return "\(start) –"
    }
}

// MARK: - OutfitAnalyticsSection

private struct OutfitAnalyticsSection: View {
    let sessions: [OutfitSession]

    private struct OutfitStat: Identifiable {
        let id = UUID()
        let name: String
        let sessionCount: Int
        let avgComfort: Double
    }

    private var stats: [OutfitStat] {
        let named = sessions.filter { !$0.name.isEmpty }
        let grouped = Dictionary(grouping: named, by: { $0.name })
        return grouped.map { name, group in
            let rated = group.filter { $0.comfortRating > 0 }
            let avgComfort = rated.isEmpty ? 0.0
                : rated.map { Double($0.comfortRating) }.reduce(0, +) / Double(rated.count)
            return OutfitStat(name: name, sessionCount: group.count, avgComfort: avgComfort)
        }.sorted { $0.sessionCount > $1.sessionCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Outfit Performance")

            if stats.isEmpty {
                Text("Name your outfits to see performance comparisons.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(stats) { stat in
                    HStack(spacing: 12) {
                        Image(systemName: "tshirt.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryGradient)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(stat.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            HStack(spacing: 8) {
                                Text("\(stat.sessionCount) session\(stat.sessionCount == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                                if stat.avgComfort > 0 {
                                    comfortBadge(stat.avgComfort)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .neonCard(glow: AppTheme.neonPurple.opacity(0.25))
    }

    @ViewBuilder
    private func comfortBadge(_ rating: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "heart.fill")
                .font(.caption2)
                .foregroundStyle(Color(red: 0.10, green: 0.85, blue: 0.80))
            Text(String(format: "%.1f comfort", rating))
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}

#Preview {
    OutfitView()
        .environment(ShiftStore())
}
