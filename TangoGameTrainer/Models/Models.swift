//
//  Models.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 31/12/2024.
//

import Foundation
import SwiftData

enum CellType: Int, Codable {
  case empty = 0
  case sun = 1
  case moon = 2
}

enum JunctionSymbol: Int, Codable, Equatable {
  case none = 0
  case equal = 1
  case opposite = 2
}

struct TangoCell: Identifiable, Codable {
  let id : UUID
  var type: CellType
  var isDefault: Bool
  var isWrong: Bool

  init(type: CellType = .empty, isDefault: Bool = false, isWrong: Bool = false) {
    self.id = UUID()
    self.type = type
    self.isDefault = isDefault
    self.isWrong = isWrong
  }
}

struct Junction: Identifiable, Codable {
  let id = UUID()
  var symbol: JunctionSymbol
  var isHorizontal: Bool
}

enum TangoLevelDifficulty: Int, Codable {
    case easy = 0
    case medium = 1
    case hard = 2
}

@Model
final class TangoLevel {
    var id: UUID
    var name: String
    var gridData: Data
    var horizontalJunctionsData: Data
    var verticalJunctionsData: Data
    var isCompleted: Bool
    var difficulty: Int // 0: easy, 1: medium, 2: hard
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        grid: [[TangoCell]],
        horizontalJunctions: [[Junction]],
        verticalJunctions: [[Junction]],
        difficulty: TangoLevelDifficulty = .medium
    ) {
        self.id = id
        self.name = name
        self.gridData = try! JSONEncoder().encode(grid)
        self.horizontalJunctionsData = try! JSONEncoder().encode(horizontalJunctions)
        self.verticalJunctionsData = try! JSONEncoder().encode(verticalJunctions)
        self.isCompleted = false
        self.difficulty = difficulty.rawValue
        self.createdAt = Date()
    }

    var grid: [[TangoCell]] {
        get {
            try! JSONDecoder().decode([[TangoCell]].self, from: gridData)
        }
        set {
            gridData = try! JSONEncoder().encode(newValue)
        }
    }

    var horizontalJunctions: [[Junction]] {
        get {
            try! JSONDecoder().decode([[Junction]].self, from: horizontalJunctionsData)
        }
        set {
            horizontalJunctionsData = try! JSONEncoder().encode(newValue)
        }
    }

    var verticalJunctions: [[Junction]] {
        get {
            try! JSONDecoder().decode([[Junction]].self, from: verticalJunctionsData)
        }
        set {
            verticalJunctionsData = try! JSONEncoder().encode(newValue)
        }
    }
}
