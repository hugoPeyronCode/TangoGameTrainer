//
//  CellView.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 31/12/2024.
//

import SwiftUI

struct CellView: View {
  let cell: TangoCell
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 0)
        .fill(cell.isDefault && cell.type != .empty ? Color.gray.opacity(0.05) : Color.white)
        .shadow(radius: 1)
        .shadow(radius: 1)
        .overlay(
          RoundedRectangle(cornerRadius: 0)
            .stroke(cell.isWrong ? Color.red : Color.clear, lineWidth: 2)
        )
      
      switch cell.type {
      case .sun:
        Circle()
          .fill(Color.yellow)
          .padding(8)
      case .moon:
        Image(systemName: "moon.fill")
          .resizable()
          .foregroundColor(.blue)
          .padding(8)
      case .empty:
        EmptyView()
      }
    }
  }
}

#Preview {
  CellView(cell: TangoCell(type: .sun, isDefault: false))
}
