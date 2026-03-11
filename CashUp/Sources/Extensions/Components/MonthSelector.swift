//
//  MonthSelector.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 12/05/25.
//

import SwiftUI

struct MonthSelector: View {
    @ObservedObject var viewModel: MonthSelectorViewModel
    var onMonthChanged: ((Date) -> Void)?
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.navigateMonth(isNext: false)
                onMonthChanged?(viewModel.selectedMonth)
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }.accessibilityIdentifier("prevMonthButton")

            Spacer()

            Text(viewModel.displayedMonth)
                .font(.headline)
                .bold()
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("currentMonthLabel")

            Spacer()

            Button(action: {
                viewModel.navigateMonth(isNext: true)
                onMonthChanged?(viewModel.selectedMonth) 
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .accessibilityIdentifier("nextMonthButton")
        }
        .padding(.horizontal)
        .frame(height: 40)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    MonthSelector(viewModel: MonthSelectorViewModel())
}

