//
//  DescriptionField.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 13/05/25.
//

import SwiftUI

struct DescriptionField: View {
    @Binding var expenseDescription: String
    private let characterLimit = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Label {
                    Text("Descrição")
                        .font(.title2)
                } icon: {
                    Image(systemName: "text.justify.left")
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                TextField("Opcional", text: $expenseDescription)
                    .font(.headline)
                    .padding(.vertical, 8)
                    .onChange(of: expenseDescription) { _, newValue in
                        if newValue.count > characterLimit {
                            expenseDescription = String(newValue.prefix(characterLimit))
                        }
                    }
            }.accessibilityIdentifier("descriptionField")

            if expenseDescription.count >= characterLimit {
                Text("Limite de 20 caracteres atingido")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Divider()
        }
    }
}
