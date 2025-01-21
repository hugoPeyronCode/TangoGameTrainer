//
//  TangoViewModel.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 31/12/2024.
//

import SwiftUI
import Combine
import SwiftData

@Observable
class TangoViewModel {
  var grid: [[TangoCell]]
  var horizontalJunctions: [[Junction]]
  var verticalJunctions: [[Junction]]
  var elapsedTime: TimeInterval = 0
  var hasWon: Bool = false
  var hasStarted: Bool = false
  var level: TangoLevel
  private var timer: Timer?
  private let validationDelay: TimeInterval = 3.5
  private let modelContext: ModelContext
  
  init(level: TangoLevel, modelContext: ModelContext) {
      self.level = level
      self.modelContext = modelContext
      self.grid = level.grid
      self.horizontalJunctions = level.horizontalJunctions
      self.verticalJunctions = level.verticalJunctions
      startTimer()
  }

  func startTimer() {
    timer?.invalidate() // Clear any existing timer
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.elapsedTime += 1
    }
  }
  
  func toggleCell(at position: (Int, Int)) {
    var newType: CellType = .empty
    let currentType = grid[position.0][position.1].type
    
    // Don't allow changing default cells
    if grid[position.0][position.1].isDefault {
      return
    }
    
    switch currentType {
    case .empty:
      newType = .sun
      hasStarted = true
    case .sun:
      newType = .moon
    case .moon:
      newType = .empty
    }
    
    grid[position.0][position.1].type = newType
    
    // Update hasStarted by checking if any cell is non-empty
    hasStarted = grid.contains { row in
      row.contains { cell in
        cell.type != .empty
      }
    }
    
    validateBoard()
  }
  
  func validateBoard() {
    // First reset all error states immediately
    for row in 0..<grid.count {
      for col in 0..<grid[row].count {
        grid[row][col].isWrong = false
      }
    }
    
    // Always delay the validation
    DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay) { [weak self] in
      self?.performValidation()
    }
  }
  
  private func performValidation() {
    // Check rows and columns separately
    for i in 0..<grid.count {
      let rowErrors = findErrors(in: grid[i].map { $0.type })
      if let indices = rowErrors {
        // Mark error cells in this row
        for col in indices {
          grid[i][col].isWrong = true
        }
      }
      
      // Get column types
      let columnTypes = (0..<grid.count).map { row in grid[row][i].type }
      let columnErrors = findErrors(in: columnTypes)
      if let indices = columnErrors {
        // Mark error cells in this column
        for row in indices {
          grid[row][i].isWrong = true
        }
      }
    }
    
    // Also validate junction rules if the level has them
    validateJunctionRules()
    
    // Check win condition
    checkWinCondition()
  }
  
  private func validateJunctionRules() {
    // Validate horizontal junctions
    for row in 0..<level.horizontalJunctions.count {
      for col in 0..<level.horizontalJunctions[row].count {
        let leftCell = grid[row][col]
        let rightCell = grid[row][col + 1]
        
        if leftCell.type != .empty && rightCell.type != .empty {
          switch level.horizontalJunctions[row][col].symbol {
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
    for row in 0..<level.verticalJunctions.count {
      for col in 0..<level.verticalJunctions[row].count {
        let topCell = grid[row][col]
        let bottomCell = grid[row + 1][col]
        
        if topCell.type != .empty && bottomCell.type != .empty {
          switch level.verticalJunctions[row][col].symbol {
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
  
  private func findErrors(in sequence: [CellType]) -> Set<Int>? {
    var errorIndices = Set<Int>()
    
    // Find consecutive symbols (3 or more)
    var consecutiveCount = 1
    var currentType: CellType = .empty
    var startIndex = 0
    
    for (index, cellType) in sequence.enumerated() {
      if cellType != .empty {
        if cellType == currentType {
          consecutiveCount += 1
          if consecutiveCount >= 3 {
            // Mark all cells in the consecutive sequence
            for i in startIndex...index {
              errorIndices.insert(i)
            }
          }
        } else {
          currentType = cellType
          consecutiveCount = 1
          startIndex = index
        }
      } else {
        currentType = .empty
        consecutiveCount = 1
      }
    }
    
    // Check if sequence is complete (all filled)
    let nonEmptyCells = sequence.filter { $0 != .empty }
    if nonEmptyCells.count == 6 {
      let suns = sequence.filter { $0 == .sun }.count
      let moons = sequence.filter { $0 == .moon }.count
      
      // If not equal number of suns and moons, mark entire sequence
      if suns != moons {
        errorIndices = Set(0..<sequence.count)
      }
    }
    
    return errorIndices.isEmpty ? nil : errorIndices
  }
  
  private func checkWinCondition() {
    let allCellsFilled = grid.allSatisfy { row in
      row.allSatisfy { $0.type != .empty }
    }
    let noErrors = grid.allSatisfy { row in
      row.allSatisfy { !$0.isWrong }
    }
    
    let wasntWonBefore = !hasWon
    hasWon = allCellsFilled && noErrors
    
    // If just won, mark level as completed and update best time
    if hasWon && wasntWonBefore {
      level.isCompleted = true
      
      // Update best time if this is the first completion or if it's a better time
      if level.bestTime == nil || elapsedTime < level.bestTime! {
        level.bestTime = elapsedTime
      }
      
      do {
        try modelContext.save()
      } catch {
        print("Failed to save level completion state: \(error)")
      }
    }
  }
  
  func clearGrid() {
    for row in 0..<grid.count {
      for col in 0..<grid[row].count {
        if !grid[row][col].isDefault {
          grid[row][col] = TangoCell()
        }
      }
    }
    hasWon = false
    hasStarted = false
  }
  
  func resetGame() {
    elapsedTime = 0
    clearGrid()
    startTimer()
  }
  
  
  deinit {
    timer?.invalidate()
  }
}
