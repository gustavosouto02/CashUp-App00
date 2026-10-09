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
        guard calendar.startOfDay(for: dataFim) >= calendar.startOfDay(for: inicio) else {
            throw CashUpDomainError.dataFimAnteriorAoInicio
        }
        let limite = calendar.date(byAdding: .year, value: limiteMaximoAnos, to: inicio) ?? inicio
        guard dataFim <= limite else {
            throw CashUpDomainError.dataFimMuitoDistante
        }
    }
}
