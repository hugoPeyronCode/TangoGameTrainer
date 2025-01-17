//
//  HomeView.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 10/01/2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \TangoLevel.createdAt) private var levels: [TangoLevel]
  @State private var selectedLevel: TangoLevel?

  var body: some View {
    NavigationStack {
      VStack {
        if let level = selectedLevel {
          GameView(level: level, modelContext: modelContext)
        } else {
          List {
            ForEach(levels) { level in
              Button(action: { selectedLevel = level }) {
                HStack {
                  VStack(alignment: .leading) {
                    Text(level.name)
                      .font(.headline)
                    Text(difficultyText(for: level))
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }

                  Spacer()

                  if level.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundStyle(.green)
                  }
                }
              }
            }
          }

          NavigationLink("Create New Level") {
            LevelEditorView(viewModel: TangoEditorViewModel(modelContext: modelContext))
          }
          .buttonStyle(.borderedProminent)
          .padding()
        }
      }
      .navigationTitle("Tango Levels")
    }
  }

  private func difficultyText(for level: TangoLevel) -> String {
    switch TangoLevelDifficulty(rawValue: level.difficulty) ?? .medium {
    case .easy: return "Easy"
    case .medium: return "Medium"
    case .hard: return "Hard"
    }
  }

  private func TangoLevelListButton(level: Int, isSelected: Bool) -> some View {
    HStack {
      Text("Tango level \(level)")
        .foregroundStyle(isSelected ? .primary : .secondary)
      Spacer()
      Image(systemName: "checkmark")
    }
  }

}

#Preview {
  HomeView()
}
