//
//  TipFlowApp.swift
//  TipFlow
//
//  Created by Katrina The Ballerina on 3/8/26.
//

import SwiftUI

@main
struct TipFlowApp: App {
    @State private var store = ShiftStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
