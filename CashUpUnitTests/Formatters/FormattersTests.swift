import XCTest

@testable import CashUp

final class FormattersTests: XCTestCase {
    private func semEspacoDuro(_ texto: String) -> String {
        texto.replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    func testMoedaEmReais() {
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 1234.5)), "R$ 1.234,50")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 0)), "R$ 0,00")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: -3.2)), "-R$ 3,20")
    }

    func testTituloDeSecaoHojeOntemEDiaDaSemana() {
        let hoje = Date.make(year: 2026, month: 10, day: 9) // sexta-feira

        let ptBR = Locale(identifier: "pt_BR")
        XCTAssertEqual(SectionDateFormatter.titulo(para: hoje, hoje: hoje, locale: ptBR), "Hoje")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 8), hoje: hoje, locale: ptBR), "Ontem")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: ptBR), "Quarta, 07/10")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 10), hoje: hoje, locale: ptBR), "Sábado, 10/10")

        let enUS = Locale(identifier: "en_US")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: enUS), "Wednesday, 07/10")

        let esES = Locale(identifier: "es_ES")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: esES), "Miércoles, 07/10")
    }
}
