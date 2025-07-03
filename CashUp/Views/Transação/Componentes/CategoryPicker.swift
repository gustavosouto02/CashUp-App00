//
//  CategoryPicker.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 13/05/25.
//

import SwiftUI
import SwiftData

struct CategoryPicker: View {
    @Binding var selectedSubcategoryModel: SubcategoriaModel?
    @Binding var selectedCategoryModel: CategoriaModel?
    @Binding var isCategorySheetPresented: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    dismissKeyboard()
                    isCategorySheetPresented = true
                } label: {
                    HStack {
                        if let subModel = selectedSubcategoryModel,
                           let catModel = selectedCategoryModel {
                            CategoriasViewIcon(
                                systemName: subModel.icon,
                                cor: catModel.color,
                                size: 24
                            )

                            Text(subModel.nome)
                                .font(.title2)
                                .foregroundStyle(.primary)

                        } else {
                            Image(systemName: "square.grid.2x2")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.primary)

                            Text("Selecionar categoria")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // Expande o toque
                }
                .buttonStyle(.plain)
            }
            .background(Color.clear) // ajuda a manter a área ativa

            Divider()
        }
    }
}
