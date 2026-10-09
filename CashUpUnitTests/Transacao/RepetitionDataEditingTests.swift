import XCTest
@testable import CashUp

final class RepetitionDataEditingTests: XCTestCase {
    private let inicio = Date.make(year: 2026, month: 3, day: 10)

    func testAtualizandoPreservaDatasExcluidas() {
        let excluida = Date.make(year: 2026, month: 4, day: 10)
        let original = RepetitionData(repeatOption: .mensalmente, endDate: nil, excludedDates: [excluida])

        let atualizada = original.atualizando(opcao: .semanalmente, dataFim: nil)

        XCTAssertEqual(atualizada?.repeatOption, .semanalmente)
        XCTAssertNil(atualizada?.endDate)
        XCTAssertEqual(atualizada?.excludedDates, [excluida])
    }

    func testAtualizandoMantemDataFimNulaQuandoSerieSemFim() {
        let original = RepetitionData(repeatOption: .mensalmente, endDate: nil)

        let atualizada = original.atualizando(opcao: .mensalmente, dataFim: nil)

        XCTAssertNotNil(atualizada)
        XCTAssertNil(atualizada?.endDate)
    }

    func testAtualizandoParaNuncaRetornaNil() {
        let original = RepetitionData(repeatOption: .diariamente, endDate: inicio)

        XCTAssertNil(original.atualizando(opcao: .nunca, dataFim: nil))
    }

    func testValidarAceitaDataFimNula() {
        XCTAssertNoThrow(try RepetitionData.validar(dataFim: nil, inicio: inicio))
    }

    func testValidarAceitaDataFimNoMesmoDiaDoInicio() {
        let mesmoDiaMaisCedo = Calendar.current.startOfDay(for: inicio)
        XCTAssertNoThrow(try RepetitionData.validar(dataFim: mesmoDiaMaisCedo, inicio: inicio))
    }

    func testValidarRejeitaDataFimAnteriorAoInicio() {
        let anterior = Date.make(year: 2026, month: 3, day: 9)

        XCTAssertThrowsError(try RepetitionData.validar(dataFim: anterior, inicio: inicio)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .dataFimAnteriorAoInicio)
        }
    }

    func testValidarRejeitaDataFimAlemDoLimite() {
        let alemDoLimite = Date.make(year: 2026 + RepetitionData.limiteMaximoAnos + 1, month: 3, day: 10)

        XCTAssertThrowsError(try RepetitionData.validar(dataFim: alemDoLimite, inicio: inicio)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .dataFimMuitoDistante)
        }
    }
}
