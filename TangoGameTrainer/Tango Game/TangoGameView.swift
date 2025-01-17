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

struct GameGridView: View {
    let viewModel: TangoViewModel

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
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
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
