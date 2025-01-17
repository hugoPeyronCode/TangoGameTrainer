//
//  LevelEditorView.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 03/01/2025.
//

import SwiftUI
import SwiftData

struct LevelEditorView: View {
  @Bindable var viewModel: TangoEditorViewModel
  @Environment(\.dismiss) var dismiss
  @State private var showingSaveAlert = false
  @State private var saveError: LevelSaveError?
  @State private var showingSaveError = false

  var body: some View {
    VStack {
      HStack {
        Text("Level Editor")
          .font(.title2)

        Spacer()

        if !viewModel.isPlaying {
          Toggle("Place Default", isOn: $viewModel.isPlacingDefault)
            .toggleStyle(.button)
            .tint(.blue)
        }

        Button(action: viewModel.togglePlayMode) {
          Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
        }
        .foregroundColor(.blue)
      }
      .padding()

      if !viewModel.isPlaying {
        VStack(spacing: 10) {
          Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
            Text("Easy").tag(TangoLevelDifficulty.easy)
            Text("Medium").tag(TangoLevelDifficulty.medium)
            Text("Hard").tag(TangoLevelDifficulty.hard)
          }
          .pickerStyle(.segmented)
        }
        .padding(.horizontal)
      }

      GridView(viewModel: viewModel)

      if !viewModel.isPlaying {
          Button("Save Level") {
              do {
                  try viewModel.saveLevel()
                  showingSaveAlert = true
              } catch let error as LevelSaveError {
                  saveError = error
                  showingSaveError = true
              } catch {
                  saveError = .saveFailed
                  showingSaveError = true
              }
          }
          .buttonStyle(.borderedProminent)
          .padding()
      }

      Spacer()
    }
    .alert("Success", isPresented: $showingSaveAlert) {
         Button("OK") {
             dismiss()
         }
     } message: {
         Text("Level saved successfully!")
     }
     .alert("Error", isPresented: $showingSaveError) {
         Button("OK", role: .cancel) { }
     } message: {
         Text(errorMessage)
     }
 }

 private var errorMessage: String {
     switch saveError {
     case .noDefaultCells:
         return "Please place at least one default cell in the level."
     case .saveFailed:
         return "Failed to save the level. Please try again."
     case .none:
         return "An unknown error occurred."
     }
 }
}

struct GridView: View {
  let viewModel: TangoEditorViewModel

  var body: some View {
    VStack(spacing: 1) {
      ForEach(0..<6) { row in
        HStack(spacing: 1) {
          ForEach(0..<6) { column in
            CellView(cell: viewModel.grid[row][column])
              .frame(width: 50, height: 50)
              .onTapGesture {
                viewModel.toggleCell(at: (row, column))
              }

            if column < 5 {
              JunctionView(
                junction: viewModel.horizontalJunctions[row][column], isEditable: true,
                onTap: {
                  viewModel.toggleHorizontalJunction(row: row, column: column)
                }
              )
            }
          }
        }

        if row < 5 {
          HStack(spacing: 1) {
            ForEach(0..<6) { column in
              JunctionView(
                junction: viewModel.verticalJunctions[row][column], isEditable: true,
                onTap: {
                  viewModel.toggleVerticalJunction(row: row, column: column)
                }
              )
              if column < 5 {
                Color.clear
                  .frame(width: 50, height: 16)
              }
            }
          }
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }
}

struct JunctionView: View {
  let junction: Junction
  let isEditable: Bool
  var onTap: (() -> Void)? = nil

  var body: some View {
    Text(junction.symbol == .equal ? "=" : junction.symbol == .opposite ? "×" : "")
      .font(.system(size: 14))
      .frame(width: 16, height: 16)
      .contentShape(Rectangle())
      .onTapGesture(perform: {
        if isEditable {
          onTap?()
        }
      })
      .background(.white)
  }
}

#Preview {
  PreviewContainer.shared.container {
    let context = PreviewContainer.shared.modelContext
    let sampleLevel = try! context.fetch(FetchDescriptor<TangoLevel>()).first!
    LevelEditorView(viewModel: TangoEditorViewModel(modelContext: context))
  }
}
