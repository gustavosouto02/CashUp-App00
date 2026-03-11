//
//  TransactionPicker.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 12/05/25.
//

import SwiftUI

struct TransactionPicker: View {
    @Binding var selectedTransactionType: Int

    var body: some View {
        Picker("Tipo de Transação", selection: $selectedTransactionType) {
            Text("Despesa").tag(0).accessibilityIdentifier("expenseTabButton")
            Text("Receita").tag(1).accessibilityIdentifier("incomeTabButton")
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(maxWidth: .infinity)
    }
}
