import SwiftUI

struct ColorSwatchGrid: View {
    @Binding var corSelecionada: CategoriaCor
    let categoriasExistentes: [CategoriaModel]
    let categoriaEmEdicaoID: UUID?

    private let colunas = [
        GridItem(.adaptive(minimum: 50), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cor da categoria")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: colunas, spacing: 16) {
                ForEach(CategoriaPalette.coresDisponiveis) { opcao in
                    let emUso = CategoriaPalette.estaEmUso(
                        cor: opcao,
                        em: categoriasExistentes,
                        ignorandoCategoriaID: categoriaEmEdicaoID
                    )
                    let selecionada = corSelecionada.id == opcao.id

                    Button {
                        guard !emUso else { return }
                        corSelecionada = opcao
                    } label: {
                        ZStack {
                            Circle()
                                .fill(opcao.color)
                                .frame(width: 44, height: 44)
                                .opacity(emUso ? 0.3 : 1.0)

                            if selecionada {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                                    .frame(width: 52, height: 52)

                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else if emUso {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(emUso)
                    .accessibilityIdentifier("colorSwatch_\(opcao.id)")
                }
            }
        }
    }
}
