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

        XCTAssertEqual(SectionDateFormatter.titulo(para: hoje, hoje: hoje), "Hoje")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 8), hoje: hoje), "Ontem")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 7), hoje: hoje), "Quarta, 07/10")
        XCTAssertEqual(SectionDateFormatter.titulo(para: Date.make(year: 2026, month: 10, day: 10), hoje: hoje), "Sábado, 10/10")
    }
}
