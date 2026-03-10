//
//  ExpensesResumoView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftUI

struct ExpensesResumoView: View {
    let income: Double
    let expense: Double
    var balance: Double {
        income - expense
    }
    //Comentario bem legal e insano
    //Testes modificados, identação corrigida
    private var saldoColor: Color {
        if balance == 0 {
            return .primary
        }
        return balance > 0 ? .green : .red
    }
    
    var body: some View {
        HStack{
            resumoItem(value: income, label: "Renda", color: .green)
            Spacer()
            resumoItem(value: expense, label: "Despesa", color: .red)
            Spacer()
            resumoItem(value: balance, label: "Saldo", color: saldoColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func resumoItem(value: Double, label: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(formatCurrency(value))
                .font(.title3)
                .bold()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
