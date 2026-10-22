import SwiftUI
import SwiftData

struct SubcategoriaPlanejadaRowView: View {
    @Bindable var subPlanejadaModel: SubcategoriaPlanejadaModel

    let corIconeCategoriaPai: Color
    var isEditing: Bool
    var isSelected: Bool
    var toggleSelection: () -> Void
    var onEditarSubcategoria: (() -> Void)? = nil
    var onValorDigitado: (() -> Void)? = nil
    var onValorAlterado: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if isEditing {
                    Button(action: toggleSelection) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: {
                    if !isEditing {
                        onEditarSubcategoria?()
                    }
                }) {
                    HStack(spacing: 8) {
                        CategoriasViewIcon(
                            systemName: subPlanejadaModel.subcategoriaOriginal?.icon ?? "questionmark.circle",
                            cor: corIconeCategoriaPai,
                            size: 22
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(subPlanejadaModel.subcategoriaOriginal?.nome ?? "Subcategoria Desconhecida")
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                if !isEditing {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isEditing)

                Spacer()

                CompactCurrencyTextField(
                    amount: $subPlanejadaModel.valorPlanejado,
                    onChanged: { _ in onValorDigitado?() },
                    onCommit: onValorAlterado
                )
            }
            .padding(.vertical, 10)
            .background(
                isEditing && isSelected ? Color.blue.opacity(0.1) : Color.clear
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing {
                    toggleSelection()
                }
            }

            Divider()
        }
    }
}
