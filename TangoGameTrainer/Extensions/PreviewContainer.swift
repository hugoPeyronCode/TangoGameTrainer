//
//  PreviewContainer.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 17/01/2025.
//

import SwiftData
import SwiftUI

@MainActor
class PreviewContainer {
    static let shared = PreviewContainer()

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    private init() {
        // Create in-memory container
        let schema = Schema([
            TangoLevel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            modelContext = ModelContext(modelContainer)

            // Create some sample levels
            let sampleLevel = TangoLevel(
                grid: Array(repeating: Array(repeating: TangoCell(type: .empty, isDefault: true), count: 6), count: 6),
                horizontalJunctions: Array(repeating: Array(repeating: Junction(symbol: .equal, isHorizontal: true), count: 5), count: 6),
                verticalJunctions: Array(repeating: Array(repeating: Junction(symbol: .opposite, isHorizontal: false), count: 6), count: 5),
                difficulty: .medium
            )

            modelContext.insert(sampleLevel)
            try modelContext.save()

        } catch {
            fatalError("Could not create preview container: \(error.localizedDescription)")
        }
    }

    // Helper to create a preview wrapper
    func container<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        content()
            .modelContainer(modelContainer)
    }
}
