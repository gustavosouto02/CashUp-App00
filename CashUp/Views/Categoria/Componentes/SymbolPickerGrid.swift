import SwiftUI

struct SymbolPickerGrid: View {
    @Binding var iconeSelecionado: String
    let corDestaque: Color

    @State private var grupoSelecionadoIndex: Int = 0

    private let colunas = [
        GridItem(.adaptive(minimum: 46), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ícone")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(CategoriaSymbols.grupos.enumerated()), id: \.element.id) { index, grupo in
                        let ativo = grupoSelecionadoIndex == index
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                grupoSelecionadoIndex = index
                            }
                        } label: {
                            Text(grupo.titulo)
                                .font(.caption.weight(ativo ? .bold : .medium))
                                .foregroundStyle(ativo ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(ativo ? corDestaque : Color(.tertiarySystemFill))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            let grupoAtual = CategoriaSymbols.grupos[min(grupoSelecionadoIndex, CategoriaSymbols.grupos.count - 1)]

            LazyVGrid(columns: colunas, spacing: 12) {
                ForEach(grupoAtual.simbolos, id: \.self) { simbolo in
                    let selecionado = iconeSelecionado == simbolo

                    Button {
                        iconeSelecionado = simbolo
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selecionado ? corDestaque : Color(.tertiarySystemFill))
                                .frame(width: 44, height: 44)

                            Image(systemName: simbolo)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selecionado ? .white : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("symbol_\(simbolo)")
                }
            }
        }
    }
}
