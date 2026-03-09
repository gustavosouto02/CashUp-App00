//
//  CategoriesViewEdit.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI
import SwiftData

struct CategoriesViewEdit: View {
    @Query(sort: \CategoriaModel.nome) private var categorias: [CategoriaModel]
    
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        NavigationStack {
            List {
                if categorias.isEmpty {
                    Text("Nenhuma categoria encontrada. Tente adicionar algumas.")
                } else {
                    ForEach(categorias) { categoriaModel in
                        CategoriaSectionView(categoria: categoriaModel)
                        // .swipeActions {
                        //     Button("Deletar", systemImage: "trash", role: .destructive) {
                        //         // Adicionar confirmação antes de deletar
                        //         deleteCategoria(categoriaModel)
                        //     }
                        // }
                    }
                }
            }
            .navigationTitle("Editar Categorias")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Adicionar Nova Categoria", systemImage: "plus.circle") {
                            // addNewCategoria()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    // func addNewCategoria() {
    //     // Apresentar um sheet ou navegação para criar uma nova CategoriaModel
    //     // let novaCategoria = CategoriaModel(nome: "Nova Categoria", icon: "square.grid.2x2", color: .gray)
    //     // modelContext.insert(novaCategoria)
    //     // try? modelContext.save()
    // }

    // func deleteCategoria(_ categoria: CategoriaModel) {
    //     modelContext.delete(categoria)
    //     // try? modelContext.save()
    // }
}

struct CategoriaSectionView: View { //
    @Bindable var categoria: CategoriaModel

    var body: some View {
        Section {
            ForEach(categoria.subcategorias) { sub in
                HStack(spacing: 12) {
                    CategoriasViewIcon(systemName: sub.icon, cor: categoria.color, size: 24)
                    Text(sub.nome)
                        .foregroundStyle(.primary)
                    // Adicionar botões de editar/deletar subcategoria
                }
                .padding(.vertical, 4)
            }
        } header: {
            HStack(spacing: 8) {
                CategoriasViewIcon(systemName: categoria.icon, cor: categoria.color, size: 24)
                Text(categoria.nome)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 6)
            .padding(.leading, -20)
        }
    }
}

