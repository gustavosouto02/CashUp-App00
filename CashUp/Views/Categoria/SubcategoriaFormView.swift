import SwiftUI

struct SubcategoriaFormView: View {
    @Environment(\.dismiss) private var dismiss

    let categoriaPai: CategoriaModel
    let subcategoriaExistente: SubcategoriaModel?
    @ObservedObject var viewModel: CategoriaEditorViewModel
    let onSalvo: () -> Void

    @State private var nome: String = ""
    @State private var icone: String = "tag.fill"
    @State private var erroLocal: String?

    init(categoriaPai: CategoriaModel, subcategoriaExistente: SubcategoriaModel? = nil, viewModel: CategoriaEditorViewModel, onSalvo: @escaping () -> Void = {}) {
        self.categoriaPai = categoriaPai
        self.subcategoriaExistente = subcategoriaExistente
        self.viewModel = viewModel
        self.onSalvo = onSalvo

        if let existente = subcategoriaExistente {
            _nome = State(initialValue: existente.nome)
            _icone = State(initialValue: existente.icon)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    previewAoVivo

                    campoNome

                    SymbolPickerGrid(
                        iconeSelecionado: $icone,
                        corDestaque: categoriaPai.color
                    )
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    if let erroLocal {
                        Text(erroLocal)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .accessibilityIdentifier("subcategoriaFormErrorText")
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(subcategoriaExistente == nil ? "Nova Subcategoria" : "Editar Subcategoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(subcategoriaExistente == nil ? "Adicionar" : "Salvar") {
                        salvar()
                    }
                    .font(.headline.weight(.semibold))
                    .disabled(nome.trimmingCharacters(in: .whitespaces).count < 2)
                    .accessibilityIdentifier("subcategoriaFormSaveButton")
                }
            }
        }
        .presentationBackground(Color.black)
    }

    private var previewAoVivo: some View {
        VStack(spacing: 10) {
            CategoriasViewIcon(
                systemName: icone,
                cor: categoriaPai.color,
                size: 32
            )

            VStack(spacing: 4) {
                Text(nome.isEmpty ? "Nome da Subcategoria" : nome)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(nome.isEmpty ? Color.gray : Color.primary)
                    .lineLimit(1)

                Text("Em \(categoriaPai.nome)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var campoNome: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nome")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(nome.count)/24")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            TextField("Ex: Café da Manhã, Cinema, Combustível", text: $nome)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .onChange(of: nome) { _, novoValor in
                    if novoValor.count > 24 {
                        nome = String(novoValor.prefix(24))
                    }
                    erroLocal = nil
                }
                .accessibilityIdentifier("subcategoriaNomeTextField")
        }
    }

    private func salvar() {
        do {
            if let existente = subcategoriaExistente {
                try viewModel.editarSubcategoria(existente, novoNome: nome, novoIcone: icone)
            } else {
                _ = try viewModel.criarSubcategoria(em: categoriaPai, nome: nome, icone: icone)
            }
            onSalvo()
            dismiss()
        } catch {
            erroLocal = error.localizedDescription
        }
    }
}
