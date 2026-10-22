import SwiftUI

struct RecommendedAddSubcategorySheet: View {
    let categorias: [CategoriaModel]
    let grupo: Regra503020Grupo
    let idsIndisponiveis: Set<UUID>
    let onSelecionar: (SubcategoriaModel) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(grupo.cor)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(grupo.rawValue)
                                .font(.headline)
                            Text(grupo.descricao)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(categoriasComSubdisponiveis) { categoria in
                    Section(categoria.nome) {
                        ForEach(categoria.subcategorias.sorted(by: { $0.nome.localizedCompare($1.nome) == .orderedAscending })) { sub in
                            linhaSubcategoria(sub: sub, categoria: categoria)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Adicionar Subcategoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var categoriasComSubdisponiveis: [CategoriaModel] {
        categorias.filter { cat in
            !cat.subcategorias.isEmpty
        }.sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
    }

    @ViewBuilder
    private func linhaSubcategoria(sub: SubcategoriaModel, categoria: CategoriaModel) -> some View {
        let jaInclusa = idsIndisponiveis.contains(sub.id)

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelecionar(sub)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                CategoriasViewIcon(
                    systemName: sub.icon.isEmpty ? "tag.fill" : sub.icon,
                    cor: categoria.color.opacity(jaInclusa ? 0.4 : 1),
                    size: 18
                )
                Text(sub.nome)
                    .foregroundStyle(jaInclusa ? .secondary : .primary)
                Spacer()
                if jaInclusa {
                    Text("Já adicionada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(jaInclusa)
    }
}
