import Foundation

struct RepetitionData: Codable, Equatable {
    static let limiteMaximoAnos = 10

    var repeatOption: RepeatOption
    var endDate: Date?
    var excludedDates: [Date]?

    init(repeatOption: RepeatOption, endDate: Date?, excludedDates: [Date]? = nil) {
        self.repeatOption = repeatOption
        self.endDate = endDate
        self.excludedDates = excludedDates
    }

    func atualizando(opcao: RepeatOption, dataFim: Date?) -> RepetitionData? {
        guard opcao != .nunca else { return nil }
        return RepetitionData(repeatOption: opcao, endDate: dataFim, excludedDates: excludedDates)
    }

    static func validar(dataFim: Date?, inicio: Date, calendar: Calendar = .current) throws {
        guard let dataFim else { return }
        let inicioDia = calendar.startOfDay(for: inicio)
        let dataFimDia = calendar.startOfDay(for: dataFim)
        guard dataFimDia >= inicioDia else {
            throw CashUpDomainError.dataFimAnteriorAoInicio
        }
        let limiteDia = calendar.date(byAdding: .year, value: limiteMaximoAnos, to: inicioDia) ?? inicioDia
        guard dataFimDia <= limiteDia else {
            throw CashUpDomainError.dataFimMuitoDistante
        }
    }
}
