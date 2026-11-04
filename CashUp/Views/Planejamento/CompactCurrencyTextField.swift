import SwiftUI

struct CompactCurrencyTextField: View {
    @Binding var amount: Int64
    var onChanged: ((Int64) -> Void)? = nil
    var onCommit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool
    @State private var text: String = ""
    private let maxDigits: Int = 9

    var body: some View {
        TextField(BRLCurrencyFormatter.string(fromCentavos: 0), text: $text)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .multilineTextAlignment(.trailing)
            .font(.subheadline.weight(.semibold))
            .onAppear {
                text = BRLCurrencyFormatter.string(fromCentavos: amount)
            }
            .onChange(of: amount) { _, newValue in
                if !isFocused {
                    text = BRLCurrencyFormatter.string(fromCentavos: newValue)
                }
            }
            .onChange(of: text) { _, newValue in
                let value = Centavos.de(digitos: newValue, maximoDeDigitos: maxDigits)

                if amount != value {
                    amount = value
                    onChanged?(value)
                }

                let formatted = BRLCurrencyFormatter.string(fromCentavos: value)
                if text != formatted {
                    text = formatted
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    let currentVal = valorDosDigitos(text)
                    if currentVal != amount {
                        text = BRLCurrencyFormatter.string(fromCentavos: amount)
                    }
                    onCommit?()
                }
            }
            .toolbar {
                if isFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Concluir") {
                            isFocused = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .frame(minWidth: 95, maxWidth: 120)
    }

    private func valorDosDigitos(_ str: String) -> Int64 {
        Centavos.de(digitos: str, maximoDeDigitos: Int.max)
    }
}
