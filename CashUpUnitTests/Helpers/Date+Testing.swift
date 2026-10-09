//
//  Date+Testing.swift
//  CashUpUnitTests
//
//  Fábrica de datas fixas para os testes. Nenhum teste monta dados com `Date()`
//  quando o resultado é comparado a um mês específico (Etapa 3 do plano).
//

import Foundation

extension Date {
    static func make(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
