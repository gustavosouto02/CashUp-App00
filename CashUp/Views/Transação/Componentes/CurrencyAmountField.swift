//
//  CurrencyAmountField.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 13/05/25.
//

import SwiftUI

struct CurrencyAmountField: View {
    @Binding var amount: Int64
    @FocusState private var isFocused: Bool
    @State private var text: String = ""

    private let maxDigits: Int = 10

    var body: some View {
        VStack(spacing: 4) {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .onAppear {
                    text = BRLCurrencyFormatter.string(fromCentavos: amount)
                }
                .onChange(of: text) { _, newValue in
                    let value = Centavos.de(digitos: newValue, maximoDeDigitos: maxDigits)
                    amount = value
                    text = BRLCurrencyFormatter.string(fromCentavos: value)
                }
                .font(.system(size: 48, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 280, height: 70)
                .accessibilityIdentifier("amountField")
        }
    }
}
