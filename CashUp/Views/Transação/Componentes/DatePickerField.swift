//
//  DatePickerField.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 13/05/25.
//

import SwiftUI

struct DatePickerField: View {
    @Binding var selectedDate: Date
    var formattedDate: String

    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .resizable()
                .frame(width: 24, height: 24)

            Text("Data:")
                .font(.title2)

            Spacer()
            
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .padding(.trailing, 45)
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: 120)
        }
        Divider()
    }
}
