//
//  TangoGameView.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 31/12/2024.

import SwiftUI
import SwiftData

struct GameView: View {
  @State var viewModel: TangoViewModel
  @State private var showingClearConfirmation: Bool = false
  @State private var showingExitConfirmation: Bool = false
  @State private var showingWinAlert: Bool = false
  @Environment(\.dismiss) private var dismiss

  init(level: TangoLevel, modelContext: ModelContext) {
    self.viewModel = TangoViewModel(level: level, modelContext: modelContext)
  }

  var formattedTime: String {
    let minutes = Int(viewModel.elapsedTime) / 60
    let seconds = Int(viewModel.elapsedTime) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  var body: some View {
    VStack {
      HStack {
        Spacer()

        Text(formattedTime)
          .font(.title3)
          .monospacedDigit()

        CapsuleButton(text: "clear", isActive: $viewModel.hasStarted) {
          showingClearConfirmation = true
        }

        Button(action: {
          // Show help/rules
        }) {
          Image(systemName: "questionmark.circle")
            .foregroundColor(.blue)
        }
      }
      .padding()

      GameGridView(viewModel: viewModel)

      Spacer()
    }
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          showingExitConfirmation = true
        } label: {
          HStack {
            Image(systemName: "chevron.left")
            Text("Tango")
          }
        }
      }
    }
    .alert("Clear Grid", isPresented: $showingClearConfirmation) {
      Button("Cancel", role: .cancel) { }
      Button("Clear", role: .destructive) {
        viewModel.clearGrid()
      }
    } message: {
      Text("Are you sure you want to clear the grid? This action cannot be undone.")
    }
    .alert("Leave Level", isPresented: $showingExitConfirmation) {
      Button("Cancel", role: .cancel) { }
      Button("Leave", role: .destructive) {
        viewModel.resetGame()
        dismiss()
      }
    } message: {
      Text("Are you sure you want to leave? The game progress and timer will be reset.")
    }
    .alert("Congratulations!", isPresented: $showingWinAlert) {
      Button("Continue") {
        viewModel.resetGame()  // Reset before dismissing
        dismiss()
      }
    } message: {
      Text("You've completed the level in \(formattedTime)!")
    }
    .onChange(of: viewModel.hasWon) { oldValue, newValue in
      if newValue {
        showingWinAlert = true
      }
    }
  }
}

// Main grid view
struct GameGridView: View {
  let viewModel: TangoViewModel

  var body: some View {
    VStack(spacing: 0) { // Remove spacing between rows
      ForEach(0..<6) { row in
        HStack(spacing: 0) { // Remove spacing between cells
          ForEach(0..<6) { column in
            CellView(cell: viewModel.grid[row][column])
              .frame(width: 50, height: 50)
              .overlay(alignment: .trailing) {
                if column < 5 {
                  // Horizontal junction
                  Text(viewModel.horizontalJunctions[row][column].symbol == .equal ? "=" :
                        viewModel.horizontalJunctions[row][column].symbol == .opposite ? "×" : "")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(Color.brown.opacity(0.6))
                }
              }
              .overlay(alignment: .bottom) {
                if row < 5 {
                  // Vertical junction
                  Text(viewModel.verticalJunctions[row][column].symbol == .equal ? "=" :
                        viewModel.verticalJunctions[row][column].symbol == .opposite ? "×" : "")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(Color.brown.opacity(0.6))
                }
              }
              .onTapGesture {
                viewModel.toggleCell(at: (row, column))
              }
          }
        }
      }
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    )
    .padding()
  }
}

// Single row of cells with horizontal junctions
struct GridRow: View {
  let viewModel: TangoViewModel
  let row: Int

  var body: some View {
    HStack(spacing: 1) {
      ForEach(0..<6) { column in
        CellView(cell: viewModel.grid[row][column])
          .frame(width: 50, height: 50)
          .overlay(content: {
            if column < 5 {
              GameJunctionView(
                junction: viewModel.horizontalJunctions[row][column],
                isEditable: false
              )
            }
          })
          .onTapGesture {
            viewModel.toggleCell(at: (row, column))
          }

      }
    }
  }
}

// Row of vertical junctions
struct VerticalJunctionsRow: View {
  let viewModel: TangoViewModel
  let row: Int

  var body: some View {
    HStack(spacing: 1) {
      ForEach(0..<6) { column in
        GameJunctionView(
          junction: viewModel.verticalJunctions[row][column],
          isEditable: false
        )

        if column < 5 {
          Color.clear
            .frame(width: 16, height: 16)
        }
      }
    }
  }
}

// Simplified Junction View
struct GameJunctionView: View {
  let junction: Junction
  let isEditable: Bool

  var body: some View {
    Text(junction.symbol == .equal ? "=" : junction.symbol == .opposite ? "×" : "")
      .font(.system(size: 14))
      .frame(width: 16, height: 16)
      .background(.white)
  }
}

struct JunctionSymbolView: View {
  let symbol: JunctionSymbol

  var symbolText: String {
    switch symbol {
    case .equal: return "="
    case .opposite: return "×"
    case .none: return " "  // Using space to maintain layout
    }
  }

  var body: some View {
    Text(symbolText)
      .font(.system(size: 14, weight: .medium))
      .foregroundStyle(Color.brown.opacity(0.8))
      .frame(width: 16, height: 16)  // Fixed size even when empty
  }
}

#Preview {
  PreviewContainer.shared.container {
    let context = PreviewContainer.shared.modelContext
    let sampleLevel = try! context.fetch(FetchDescriptor<TangoLevel>()).first!
    return NavigationStack {
      GameView(level: sampleLevel, modelContext: context)
    }
  }
}
