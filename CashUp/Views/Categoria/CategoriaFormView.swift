import SwiftUI

struct CategoriaFormView: View {
    @Environment(\.dismiss) private var dismiss

    let categoriaExistente: CategoriaModel?
    @ObservedObject var viewModel: CategoriaEditorViewModel
    let onSalvo: () -> Void

    @State private var nome: String = ""
    @State private var cor: CategoriaCor
    @State private var icone: String = CategoriaSymbols.padrao
    @State private var erroLocal: String?

    private var isCategoriaBase: Bool {
        guard let existente = categoriaExistente else { return false }
        return SeedIDs.isCategoriaBase(id: existente.id)
    }

    init(categoriaExistente: CategoriaModel? = nil, viewModel: CategoriaEditorViewModel, onSalvo: @escaping () -> Void = {}) {
        self.categoriaExistente = categoriaExistente
        self.viewModel = viewModel
        self.onSalvo = onSalvo

        if let existente = categoriaExistente {
            _nome = State(initialValue: existente.nome)
            _icone = State(initialValue: existente.icon)
            let corEncontrada = CategoriaCor(
                id: "atual_\(existente.id.uuidString)",
                nome: existente.nome,
                red: existente.redComponent,
                green: existente.greenComponent,
                blue: existente.blueComponent
            )
            _cor = State(initialValue: corEncontrada)
        } else {
            _cor = State(initialValue: CategoriaPalette.primeiraDisponivel(em: viewModel.categorias))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    previewAoVivo

                    campoNome

                    if !isCategoriaBase {
                        ColorSwatchGrid(
                            corSelecionada: $cor,
                            categoriasExistentes: viewModel.categorias,
                            categoriaEmEdicaoID: categoriaExistente?.id
                        )
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    SymbolPickerGrid(
                        iconeSelecionado: $icone,
                        corDestaque: cor.color
                    )
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    if let erroLocal {
                        Text(erroLocal)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .accessibilityIdentifier("categoriaFormErrorText")
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(categoriaExistente == nil ? "Nova Categoria" : "Editar Categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(categoriaExistente == nil ? "Adicionar" : "Salvar") {
                        salvar()
                    }
                    .font(.headline.weight(.semibold))
                    .disabled(nome.trimmingCharacters(in: .whitespaces).count < 2)
                    .accessibilityIdentifier("categoriaFormSaveButton")
                }
            }
        }
        .presentationBackground(Color.black)
    }

    private var previewAoVivo: some View {
        VStack(spacing: 10) {
            CategoriasViewIcon(
                systemName: icone,
                cor: cor.color,
                size: 32
            )

            Text(nome.isEmpty ? "Nome da Categoria" : nome)
                .font(.title3.weight(.bold))
                .foregroundStyle(nome.isEmpty ? Color.gray : Color.primary)
                .lineLimit(1)
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

            TextField("Ex: Assinaturas, Pets, Carro", text: $nome)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .onChange(of: nome) { _, novoValor in
                    if novoValor.count > 24 {
                        nome = String(novoValor.prefix(24))
                    }
                    erroLocal = nil
                }
                .accessibilityIdentifier("categoriaNomeTextField")
        }
    }

    private func salvar() {
        do {
            if let existente = categoriaExistente {
                try viewModel.editarCategoria(existente, novoNome: nome, novaCor: cor, novoIcone: icone)
            } else {
                _ = try viewModel.criarCategoria(nome: nome, cor: cor, icone: icone)
            }
            onSalvo()
            dismiss()
        } catch {
            erroLocal = error.localizedDescription
        }
    }
}
