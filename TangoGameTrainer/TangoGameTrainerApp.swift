//
//  TangoGameTrainerApp.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 31/12/2024.
//

import SwiftUI
import SwiftData

@main
struct TangoGameTrainerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: TangoLevel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container)
    }
}
