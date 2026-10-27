import SwiftUI

struct SubcategoriaPickerSheet: View {
    let categoria: CategoriaModel
    let subcategoriaAtualID: UUID?
    let idsIndisponiveis: Set<UUID>
    let valorAtual: Double?
    let onSelecionar: (SubcategoriaModel) -> Void

    @Environment(\.dismiss) private var dismiss

    private var subcategorias: [SubcategoriaModel] {
        (categoria.subcategorias ?? []).sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        CategoriasViewIcon(systemName: categoria.icon, cor: categoria.color, size: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(categoria.nome)
                                .font(.headline)
                            if let valorAtual {
                                Text("Valor planejado: \(BRLCurrencyFormatter.string(from: valorAtual))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("O valor planejado é mantido ao trocar a subcategoria.")
                }

                if subcategorias.isEmpty {
                    Section {
                        Text("Nenhuma outra subcategoria disponível nesta categoria.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                } else {
                    Section("Subcategorias") {
                        ForEach(subcategorias) { sub in
                            linha(sub)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trocar Subcategoria")
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

    @ViewBuilder
    private func linha(_ sub: SubcategoriaModel) -> some View {
        let isAtual = sub.id == subcategoriaAtualID
        let indisponivel = idsIndisponiveis.contains(sub.id)

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelecionar(sub)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                CategoriasViewIcon(
                    systemName: sub.icon.isEmpty ? "tag.fill" : sub.icon,
                    cor: categoria.color.opacity(indisponivel ? 0.4 : 1),
                    size: 18
                )
                Text(sub.nome)
                    .foregroundStyle(indisponivel ? .secondary : .primary)
                Spacer()
                if isAtual {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                } else if indisponivel {
                    Text("Já planejada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAtual || indisponivel)
        .accessibilityIdentifier("picker_subcategoria_\(sub.nome)")
    }
}
