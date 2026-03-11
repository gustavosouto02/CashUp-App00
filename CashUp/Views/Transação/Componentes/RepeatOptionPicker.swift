//
//  RepeatOptionPicker.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 27/05/25.
//

import SwiftUI

enum RepeatOption: String, CaseIterable, Identifiable, Codable {
    case nunca = "Nunca"
    case diariamente = "Diariamente"
    case semanalmente = "Semanalmente"
    case aCada10Dias = "A cada 10 dias"
    case mensalmente = "Mensalmente"
    case anualmente = "Anualmente"
    
    var id: String { self.rawValue }
}

import SwiftUI

struct RepeatOptionPicker: View {
    @Binding var repeatOption: RepeatOption
    @Binding var isRepeatDialogPresented: Bool
    @Binding var repeatEndDate: Date?
    var selectedDate: Date

    @State private var shouldSuggestEndDate: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    dismissKeyboard() 
                    isRepeatDialogPresented = true
                }) {
                    HStack(spacing: 4) {
                        Label("Repetir", systemImage: "repeat")
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(repeatOption.rawValue)
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .accessibilityIdentifier("repeatOptionButton")
            }
            .confirmationDialog("Escolha a frequência de repetição", isPresented: $isRepeatDialogPresented, titleVisibility: .visible) {
                ForEach(RepeatOption.allCases) { option in
                    Button(option.rawValue) {
                        let oldValue = repeatOption
                        repeatOption = option
                        if option == .nunca {
                            repeatEndDate = nil
                            shouldSuggestEndDate = false
                        } else if oldValue == .nunca && option != .nunca && repeatEndDate == nil {
                            shouldSuggestEndDate = true
                        }else if option != .nunca && repeatEndDate != nil {
                            shouldSuggestEndDate = false
                        }
                    }
                }
            }
            
            if repeatOption != .nunca {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.top, 4)
                    HStack {
                        Text("Parar repetição em")
                            .font(.headline)
                        Spacer()
                        DatePicker(
                            "Data de término",
                            selection: Binding(
                                get: { repeatEndDate ?? calculateDefaultEndDate() },
                                set: { newValue in
                                    repeatEndDate = newValue
                                    shouldSuggestEndDate = false
                                }
                            ),
                            in: selectedDate...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                        .padding(shouldSuggestEndDate && repeatEndDate == nil ? 1 : 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(shouldSuggestEndDate && repeatEndDate == nil ? Color.orange : Color.clear, lineWidth: 2)
                                .animation(.easeInOut, value: shouldSuggestEndDate && repeatEndDate == nil)
                        )
                    }
                    if shouldSuggestEndDate && repeatEndDate == nil {
                        Text("Opcional: defina uma data para encerrar a repetição ou ela continuará por 1 ano como padrão.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.leading, 2) 
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.top, 8)
                .animation(.default, value: repeatOption)
            }
        }
        .onChange(of: repeatOption) { _, newOption in
            if newOption == .nunca {
                shouldSuggestEndDate = false
            }
            if newOption != .nunca && repeatEndDate != nil {
                shouldSuggestEndDate = false
            }
        }
    }

    private func calculateDefaultEndDate() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) ?? selectedDate
    }
}
