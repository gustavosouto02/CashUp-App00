//
//  CategoriaFiltroView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI
import SwiftData

struct CategoriaFiltroView: View {
    var categorias: [CategoriaModel]
    @Binding var selectedCategoriaID: UUID?
    var onSubcategoriaSelected: (SubcategoriaModel) -> Void
    var subcategoriasFrequentes: [SubcategoriaModel]
    var transactionType: TransactionTypeFilter
    
    private let buttonSize: CGFloat = 70
    private let buttonCornerRadius: CGFloat = 12
    
    private func categoriaButton(categoriaModel: CategoriaModel) -> some View {
        Button(action: {
            selectedCategoriaID = categoriaModel.id
        }) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .fill(selectedCategoriaID == categoriaModel.id ? categoriaModel.color.opacity(0.25) : Color.gray.opacity(0.10))
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Image(systemName: categoriaModel.icon)
                            .font(.system(size: 26))
                            .foregroundStyle(selectedCategoriaID == categoriaModel.id ? categoriaModel.color : Color.primary.opacity(0.7))
                    )
                
                if selectedCategoriaID == categoriaModel.id {
                    Text(categoriaModel.nome)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: buttonSize + 10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func subcategoriaCard(categoriaModel: CategoriaModel?, subcategoriaModel: SubcategoriaModel) -> some View {
        VStack(spacing: 4) {
            CategoriasViewIcon(
                systemName: subcategoriaModel.icon,
                cor: categoriaModel?.color ?? .gray,
                size: 30
            )
            
            Text(subcategoriaModel.nome)
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(height: 30)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSubcategoriaSelected(subcategoriaModel)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            if !subcategoriasFrequentes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mais Frequentes")
                        .font(.headline.bold())
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .foregroundStyle(.primary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(subcategoriasFrequentes) { subModel in
                                let corCategoriaPai = subModel.categoria?.color ?? .gray
                                VStack(spacing: 4) {
                                    CategoriasViewIcon(
                                        systemName: subModel.icon,
                                        cor: corCategoriaPai,
                                        size: 30
                                    )
                                    Text(subModel.nome)
                                        .font(.footnote)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .frame(width: 70, height: 30)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(width: 80)
                                .onTapGesture {
                                    onSubcategoriaSelected(subModel)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            if !categorias.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if transactionType == .despesa || categorias.count > 1 {
                            Button(action: {
                                selectedCategoriaID = nil
                            }) {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                                        .fill(selectedCategoriaID == nil ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.10))
                                        .frame(width: buttonSize, height: buttonSize)
                                        .overlay(
                                            Image(systemName: "square.grid.2x2.fill")
                                                .font(.system(size: 26))
                                                .foregroundStyle(selectedCategoriaID == nil ? Color.accentColor : Color.primary.opacity(0.7))
                                        )
                                    if selectedCategoriaID == nil {
                                        Text("Todas")
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: buttonSize + 10)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        ForEach(categorias) { categoriaModel in
                            categoriaButton(categoriaModel: categoriaModel)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut, value: selectedCategoriaID)
                }
            }
            
            let categoriasParaExibir = categorias.filter { categoriaModel in
                selectedCategoriaID == nil || categoriaModel.id == selectedCategoriaID
            }
            
            if !categoriasParaExibir.isEmpty {
                ForEach(categoriasParaExibir) { categoriaModel in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(categoriaModel.nome)
                            .font(.title3.bold())
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        let subcategoriasDaCategoria = (categoriaModel.subcategorias).sorted { $0.nome < $1.nome }
                        
                        if !subcategoriasDaCategoria.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85, maximum: 100), spacing: 10)], spacing: 10) {
                                ForEach(subcategoriasDaCategoria) { subcategoriaModel in
                                    subcategoriaCard(categoriaModel: categoriaModel, subcategoriaModel: subcategoriaModel)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("Nenhuma subcategoria encontrada para \(categoriaModel.nome).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            } else if selectedCategoriaID != nil && categoriasParaExibir.isEmpty {
                Text("Nenhuma categoria corresponde ao filtro selecionado.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
