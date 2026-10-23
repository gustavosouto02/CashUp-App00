import SwiftUI

struct CompactCurrencyTextField: View {
    @Binding var amount: Double
    var onChanged: ((Double) -> Void)? = nil
    var onCommit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool
    @State private var text: String = ""
    private let maxDigits: Int = 9

    var body: some View {
        TextField(BRLCurrencyFormatter.string(from: 0), text: $text)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .multilineTextAlignment(.trailing)
            .font(.subheadline.weight(.semibold))
            .onAppear {
                text = BRLCurrencyFormatter.string(from: amount)
            }
            .onChange(of: amount) { _, newValue in
                if !isFocused {
                    text = BRLCurrencyFormatter.string(from: newValue)
                }
            }
            .onChange(of: text) { _, newValue in
                let digits = newValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let limitedDigits = String(digits.prefix(maxDigits))
                let value = (Double(limitedDigits) ?? 0.0) / 100.0

                if amount != value {
                    amount = value
                    onChanged?(value)
                }

                let formatted = BRLCurrencyFormatter.string(from: value)
                if text != formatted {
                    text = formatted
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    let currentVal = valorDosDigitos(text)
                    if currentVal != amount {
                        text = BRLCurrencyFormatter.string(from: amount)
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

    private func valorDosDigitos(_ str: String) -> Double {
        let digits = str.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return (Double(digits) ?? 0.0) / 100.0
    }
}
