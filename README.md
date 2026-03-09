# TipFlow

A real-time shift analytics tool built with SwiftUI that helps track interactions, earnings, and performance metrics during nightlife shifts through simple tap-based logging and smart interaction timers.

## Features

- **Dashboard** — Live earnings totals, progress toward nightly goal, and active interaction timer
- **Quick Input** — Large one-tap buttons for logging lap dances, stage tips, and random tips
- **Interaction Timer** — Track customer interactions with automatic 1-minute prompts and extend/convert/end options
- **Analytics** — Per-shift stats including earnings per hour, conversion rate, and average interaction length
- **Persistence** — Shift records saved locally via JSON/UserDefaults

## Architecture

```
TipFlow/
├── App/                  # App entry point and tab navigation
│   ├── TipFlowApp.swift
│   └── ContentView.swift
├── Models/               # Data models (Earning, Interaction, Shift)
│   ├── Earning.swift
│   ├── Interaction.swift
│   └── Shift.swift
├── ViewModels/           # State management and business logic
│   └── ShiftViewModel.swift
├── Views/                # SwiftUI views
│   ├── DashboardView.swift
│   ├── QuickInputView.swift
│   ├── InteractionTimerView.swift
│   ├── EndInteractionView.swift
│   ├── AnalyticsView.swift
│   └── CustomAmountView.swift
└── Persistence/          # Local data storage
    └── PersistenceController.swift
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository
2. Open the project in Xcode
3. Add the Swift source files to an iOS App target
4. Build and run on a simulator or device

## Testing

Model tests can be run via Swift Package Manager:

```bash
swift test
```
