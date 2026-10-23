import XCTest

@testable import CashUp

final class FormattersTests: XCTestCase {
    private func semEspacoDuro(_ texto: String) -> String {
        texto.replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    func testMoedaEmReais() {
        let ptBR = Locale(identifier: "pt_BR")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 1234.5, locale: ptBR)), "R$ 1.234,50")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 0, locale: ptBR)), "R$ 0,00")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: -3.2, locale: ptBR)), "-R$ 3,20")
    }

    func testMoedaEmDolarEEuro() {
        let enUS = Locale(identifier: "en_US")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 1234.5, locale: enUS)), "$1,234.50")

        let esES = Locale(identifier: "es_ES")
        XCTAssertEqual(semEspacoDuro(BRLCurrencyFormatter.string(from: 1234.5, locale: esES)), "1234,50 €")
    }

    func testTituloDeSecaoHojeOntemEDiaDaSemana() {
        let hoje = Date.make(year: 2026, month: 10, day: 9) // sexta-feira

        let ptBR = Locale(identifier: "pt_BR")
        XCTAssertEqual(SectionDateFormatter.titulo(para: hoje, hoje: hoje, locale: ptBR), "Hoje")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 8), hoje: hoje, locale: ptBR), "Ontem")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: ptBR), "Quarta, 07/10")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 10), hoje: hoje, locale: ptBR), "Sábado, 10/10")

        let enUS = Locale(identifier: "en_US")
        XCTAssertEqual(SectionDateFormatter.titulo(para: hoje, hoje: hoje, locale: enUS), "Today")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 8), hoje: hoje, locale: enUS), "Yesterday")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: enUS), "Wednesday, 07/10")

        let esES = Locale(identifier: "es_ES")
        XCTAssertEqual(SectionDateFormatter.titulo(para: hoje, hoje: hoje, locale: esES), "Hoy")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 8), hoje: hoje, locale: esES), "Ayer")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje, locale: esES), "Miércoles, 07/10")
    }
}
