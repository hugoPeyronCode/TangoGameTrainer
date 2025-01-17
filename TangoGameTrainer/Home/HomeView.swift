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

  var body: some View {
    NavigationStack {
      List {
        ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
          NavigationLink {
            GameView(level: level, modelContext: modelContext)
          } label: {
            LevelRow(index: index, level: level)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              modelContext.delete(level)
              try? modelContext.save()
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
      .navigationTitle("Tango")
      .toolbar {
        NavigationLink {
          LevelEditorView(viewModel: TangoEditorViewModel(modelContext: modelContext))
        } label: {
          Image(systemName: "plus")
        }
        .buttonStyle(.bordered)
      }
    }
  }
}

struct LevelRow: View {
  let index: Int
  let level: TangoLevel

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Level #\(index + 1)")
          .font(.headline)
        HStack {
          Text(difficultyText)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          if let bestTime = level.bestTime {
            Text("•")
              .foregroundStyle(.secondary)
            Text(formattedTime(bestTime))
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        }
      }

      Spacer()

      if level.isCompleted {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
          .imageScale(.large)
      }
    }
    .padding(.vertical, 4)
  }

  private var difficultyText: String {
    switch TangoLevelDifficulty(rawValue: level.difficulty) ?? .medium {
    case .easy: return "Easy"
    case .medium: return "Medium"
    case .hard: return "Hard"
    }
  }

  private func formattedTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}

#Preview {
  PreviewContainer.shared.container {
    HomeView()
  }
}

#Preview {
  HomeView()
}
