//
//  ContentView.swift
//  TipFlow
//
//  Created by Katrina The Ballerina on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "dollarsign.circle.fill") }
            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .environment(ShiftStore())
}
