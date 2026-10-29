import SwiftUI

struct CategoriesEditView: View {
    @StateObject private var viewModel: CategoriaEditorViewModel

    @State private var mostrandoNovaCategoria: Bool = false
    @State private var categoriaEditando: CategoriaModel?
    @State private var categoriaNovaSub: CategoriaModel?
    @State private var subcategoriaEditando: SubcategoriaModel?

    @State private var categoriaExcluindo: CategoriaModel?
    @State private var subcategoriaExcluindo: SubcategoriaModel?
    @State private var mensagemAlertaErro: String?

    init(repository: CategoriaRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: CategoriaEditorViewModel(repository: repository))
    }

    init(viewModel: CategoriaEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            
            ForEach(viewModel.categorias) { cat in
                let isRenda = cat.id == SeedIDs.idRenda
                Section {
                    ForEach(cat.subcategorias ?? []) { sub in
                        HStack(spacing: 12) {
                            CategoriasViewIcon(
                                systemName: sub.icon,
                                cor: cat.color,
                                size: 22
                            )

                            Text(sub.nome)
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            subcategoriaEditando = sub
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                subcategoriaExcluindo = sub
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                        .accessibilityIdentifier("subcategoryRow_\(sub.nome)")
                    }
                } header: {
                    HStack(spacing: 10) {
                        CategoriasViewIcon(
                            systemName: cat.icon,
                            cor: cat.color,
                            size: 24
                        )

                        Text(cat.nome)
                            .font(.title3)
                            .foregroundStyle(.primary)

                        if isRenda {
                            Text("Fixa")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Button {
                            categoriaNovaSub = cat
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.blue)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("addSubcategoriaButton_\(cat.nome)")

                        if !isRenda {
                            Button {
                                categoriaEditando = cat
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("editCategoriaButton_\(cat.nome)")

                            Button {
                                categoriaExcluindo = cat
                            } label: {
                                Image(systemName: "trash.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.red)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("deleteCategoriaButton_\(cat.nome)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Editar Categorias")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrandoNovaCategoria = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                }
                .accessibilityIdentifier("novaCategoriaToolbarButton")
            }
        }
        .sheet(isPresented: $mostrandoNovaCategoria) {
            CategoriaFormView(viewModel: viewModel)
        }
        .sheet(item: $categoriaEditando) { cat in
            CategoriaFormView(categoriaExistente: cat, viewModel: viewModel)
        }
        .sheet(item: $categoriaNovaSub) { cat in
            SubcategoriaFormView(categoriaPai: cat, viewModel: viewModel)
        }
        .sheet(item: $subcategoriaEditando) { sub in
            if let pai = sub.categoria {
                SubcategoriaFormView(categoriaPai: pai, subcategoriaExistente: sub, viewModel: viewModel)
            }
        }
        .alert("Excluir Categoria", isPresented: Binding(
            get: { categoriaExcluindo != nil },
            set: { if !$0 { categoriaExcluindo = nil } }
        )) {
            Button("Cancelar", role: .cancel) { categoriaExcluindo = nil }
            Button("Excluir", role: .destructive) {
                if let cat = categoriaExcluindo {
                    executarExclusaoCategoria(cat)
                }
            }
        } message: {
            if let cat = categoriaExcluindo {
                Text("Tem certeza que deseja apagar \"\(cat.nome)\" e suas subcategorias?")
            }
        }
        .alert("Excluir Subcategoria", isPresented: Binding(
            get: { subcategoriaExcluindo != nil },
            set: { if !$0 { subcategoriaExcluindo = nil } }
        )) {
            Button("Cancelar", role: .cancel) { subcategoriaExcluindo = nil }
            Button("Excluir", role: .destructive) {
                if let sub = subcategoriaExcluindo {
                    executarExclusaoSubcategoria(sub)
                }
            }
        } message: {
            if let sub = subcategoriaExcluindo {
                Text("Deseja apagar a subcategoria \"\(sub.nome)\"?")
            }
        }
        .alert("Atenção", isPresented: Binding(
            get: { mensagemAlertaErro != nil },
            set: { if !$0 { mensagemAlertaErro = nil } }
        )) {
            Button("OK", role: .cancel) { mensagemAlertaErro = nil }
        } message: {
            if let msg = mensagemAlertaErro {
                Text(msg)
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private func executarExclusaoCategoria(_ categoria: CategoriaModel) {
        do {
            try viewModel.apagarCategoria(categoria)
            categoriaExcluindo = nil
        } catch {
            categoriaExcluindo = nil
            mensagemAlertaErro = error.localizedDescription
        }
    }

    private func executarExclusaoSubcategoria(_ subcategoria: SubcategoriaModel) {
        do {
            try viewModel.apagarSubcategoria(subcategoria)
            subcategoriaExcluindo = nil
        } catch {
            subcategoriaExcluindo = nil
            mensagemAlertaErro = error.localizedDescription
        }
    }
}
