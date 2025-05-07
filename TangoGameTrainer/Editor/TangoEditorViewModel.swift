//
//  TangoEditorViewModel.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 16/01/2025.
//

import SwiftUI
import SwiftData

enum LevelSaveError: Error {
  case noDefaultCells
  case saveFailed
}

@Observable
class TangoEditorViewModel {
  var grid: [[TangoCell]]
  var size: Int
  var horizontalJunctions: [[Junction]]
  var verticalJunctions: [[Junction]]
  var isPlacingDefault = true
  var isPlacingJunction = false
  var isPlaying = false
  var levelName: String = ""
  var selectedDifficulty: TangoLevelDifficulty = .medium
  var hasDefaultCells: Bool { grid.contains { row in row.contains { cell in
    cell.isDefault
  }} }

  private let modelContext: ModelContext

  init(modelContext: ModelContext, size: Int = 6) {
    self.modelContext = modelContext
    self.size = size
    self.grid = Array(repeating: Array(repeating: TangoCell(), count: size), count: size)
    self.horizontalJunctions = Array(repeating: Array(repeating: Junction(symbol: .none), count: size - 1), count: size)
    self.verticalJunctions = Array(repeating: Array(repeating: Junction(symbol: .none), count: size), count: size - 1)
  }

  func reset() {
    grid = Array(repeating: Array(repeating: TangoCell(), count: size), count: size)

    horizontalJunctions = Array(repeating: Array(repeating: Junction(symbol: .none), count: size - 1), count: size)

    verticalJunctions = Array(repeating: Array(repeating: Junction(symbol: .none), count: size), count: size - 1)

    isPlaying = false
    isPlacingJunction = false
    isPlacingDefault = true
    levelName = ""
    selectedDifficulty = .medium
  }


  func saveLevel() throws {

    guard hasDefaultCells else {
      throw LevelSaveError.noDefaultCells
    }

    let level = TangoLevel(
      grid: grid,
      horizontalJunctions: horizontalJunctions,
      verticalJunctions: verticalJunctions,
      difficulty: selectedDifficulty
    )

    modelContext.insert(level)

    do {
      try modelContext.save()
    } catch {
      throw LevelSaveError.saveFailed
    }
  }

  func toggleCell(at position: (Int, Int)) {
    if isPlaying && grid[position.0][position.1].isDefault {
      return
    }

    var newType: CellType = .empty
    let currentType = grid[position.0][position.1].type

    switch currentType {
    case .empty: newType = .sun
    case .sun: newType = .moon
    case .moon: newType = .empty
    }

    grid[position.0][position.1] = TangoCell(
      type: newType,
      isDefault: isPlaying ? false : isPlacingDefault
    )

    if isPlaying {
      validateGrid()
    }
  }

  func toggleHorizontalJunction(row: Int, column: Int) {
    guard !isPlaying else { return }
    var junction = horizontalJunctions[row][column]
    switch junction.symbol {
    case .none: junction.symbol = .equal
    case .equal: junction.symbol = .opposite
    case .opposite: junction.symbol = .none
    }
    horizontalJunctions[row][column] = junction
  }

  func toggleVerticalJunction(row: Int, column: Int) {
    guard !isPlaying else { return }
    var junction = verticalJunctions[row][column]
    switch junction.symbol {
    case .none: junction.symbol = .equal
    case .equal: junction.symbol = .opposite
    case .opposite: junction.symbol = .none
    }
    verticalJunctions[row][column] = junction
  }

  private func validateGrid() {
    // Reset errors
    for row in 0..<grid.count {
      for col in 0..<grid[row].count {
        grid[row][col].isWrong = false
      }
    }

    validateBasicRules()
    validateJunctionRules()
  }

  private func validateBasicRules() {
    for i in 0..<grid.count {
      validateSequence(type: .row, index: i)
      validateSequence(type: .column, index: i)
    }
  }

  private func validateJunctionRules() {
    // Validate horizontal junctions
    for row in 0..<horizontalJunctions.count {
      for col in 0..<horizontalJunctions[row].count {
        let leftCell = grid[row][col]
        let rightCell = grid[row][col + 1]

        if leftCell.type != .empty && rightCell.type != .empty {
          switch horizontalJunctions[row][col].symbol {
          case .equal:
            if leftCell.type != rightCell.type {
              grid[row][col].isWrong = true
              grid[row][col + 1].isWrong = true
            }
          case .opposite:
            if leftCell.type == rightCell.type {
              grid[row][col].isWrong = true
              grid[row][col + 1].isWrong = true
            }
          case .none:
            break
          }
        }
      }
    }

    // Validate vertical junctions
    for row in 0..<verticalJunctions.count {
      for col in 0..<verticalJunctions[row].count {
        let topCell = grid[row][col]
        let bottomCell = grid[row + 1][col]

        if topCell.type != .empty && bottomCell.type != .empty {
          switch verticalJunctions[row][col].symbol {
          case .equal:
            if topCell.type != bottomCell.type {
              grid[row][col].isWrong = true
              grid[row + 1][col].isWrong = true
            }
          case .opposite:
            if topCell.type == bottomCell.type {
              grid[row][col].isWrong = true
              grid[row + 1][col].isWrong = true
            }
          case .none:
            break
          }
        }
      }
    }
  }

  func togglePlayMode() {
    isPlaying.toggle()
    if !isPlaying {
      resetNonDefaultCells()
    }
  }

  private func resetNonDefaultCells() {
    for row in 0..<grid.count {
      for col in 0..<grid[row].count {
        if !grid[row][col].isDefault {
          grid[row][col] = TangoCell()
        }
      }
    }
  }

  private enum SequenceType {
    case row, column
  }

  private func validateSequence(type: SequenceType, index: Int) {
    let sequence = type == .row ?
    grid[index].map { $0.type } :
    grid.map { $0[index].type }

    // Check for three consecutive symbols
    for i in 0...(sequence.count - 3) {
      if sequence[i] != .empty &&
          sequence[i] == sequence[i + 1] &&
          sequence[i] == sequence[i + 2] {
        for j in i...(i + 2) {
          if type == .row {
            grid[index][j].isWrong = true
          } else {
            grid[j][index].isWrong = true
          }
        }
      }
    }

    // Check equal numbers in completed sequences
    let nonEmptyCells = sequence.filter { $0 != .empty }
    if nonEmptyCells.count == 6 {
      let suns = sequence.filter { $0 == .sun }.count
      let moons = sequence.filter { $0 == .moon }.count
      if suns != moons {
        for i in 0..<sequence.count {
          if type == .row {
            grid[index][i].isWrong = true
          } else {
            grid[i][index].isWrong = true
          }
        }
      }
    }
  }
}
