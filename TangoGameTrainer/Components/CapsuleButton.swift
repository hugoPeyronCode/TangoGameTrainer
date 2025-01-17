//
//  CapsuleButton.swift
//  TangoGameTrainer
//
//  Created by Hugo Peyron on 10/01/2025.
//

import SwiftUI

struct CapsuleButton: View {
  let text: String
  let color: Color
  @Binding var isActive: Bool

  init(text: String, color: Color, isActive: Binding<Bool>, action: @escaping () -> Void) {
    self.text = text
    self.color = color
    self._isActive = isActive
    self.action = action
  }

  init(text: String, isActive: Binding<Bool>, action: @escaping () -> Void) {
    self.text = text
    self.color = .primary
    self._isActive = isActive
    self.action = action
  }

  let action: ()->Void

  var body: some View {
    Button {
      action()
    } label: {
      Text(text.capitalized)
        .foregroundStyle(!isActive ? .gray : color)
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
        .overlay {
          RoundedRectangle(cornerRadius: 15)
            .stroke(lineWidth: 1)
            .foregroundStyle(!isActive ? .gray : color)
        }
    }
    .disabled(!isActive)
  }
}

#Preview {
  CapsuleButton(text: "clear", color: .primary, isActive: .constant(true)) {}
}
