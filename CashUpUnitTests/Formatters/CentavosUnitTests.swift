import XCTest

@testable import CashUp

final class CentavosUnitTests: XCTestCase {
    private func semEspacoDuro(_ texto: String) -> String {
        texto.replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    func testSomaDeDezComVinteCentavosEhExatamenteTrintaCentavos() {
        let dez = Centavos.de(reais: 0.10)
        let vinte = Centavos.de(reais: 0.20)

        XCTAssertEqual(dez + vinte, 30)
        // Em Double, 0,1 + 0,2 não é 0,3: é isso que a E0.3 elimina.
        XCTAssertNotEqual(0.1 + 0.2, 0.3)
    }

    func testReaisDoubleParaCentavosArredondaEmVezDeTruncar() {
        XCTAssertEqual(Centavos.de(reais: 0.29), 29)
        XCTAssertEqual(Centavos.de(reais: 4.35), 435)
        XCTAssertEqual(Centavos.de(reais: 19.899999), 1990)
        XCTAssertEqual(Centavos.de(reais: 1.005), 101)
        XCTAssertEqual(Centavos.de(reais: 2.675), 268)
        XCTAssertEqual(Centavos.de(reais: 1234567.89), 123_456_789)
        XCTAssertEqual(Centavos.de(reais: Double(0)), 0)
    }

    func testNegativosArredondamParaLongeDoZero() {
        XCTAssertEqual(Centavos.de(reais: -3.2), -320)
        XCTAssertEqual(Centavos.de(reais: Decimal(string: "-0.005")!), -1)
        XCTAssertEqual(Centavos.de(reais: Decimal(string: "0.005")!), 1)
        XCTAssertEqual(Centavos.de(reais: Decimal(string: "0.004")!), 0)
    }

    func testValoresNaoFinitosViramZeroEGigantescosSaoLimitados() {
        XCTAssertEqual(Centavos.de(reais: Double.nan), 0)
        XCTAssertEqual(Centavos.de(reais: Double.infinity), 0)
        XCTAssertEqual(Centavos.de(reais: 1e30), Centavos.limite)
        XCTAssertEqual(Centavos.de(reais: -1e30), -Centavos.limite)
    }

    func testIdaEVoltaCentavosDecimal() {
        for centavos: Int64 in [0, 1, 9, 10, 99, 100, 123_456_789, -250] {
            XCTAssertEqual(Centavos.de(reais: Centavos.reais(de: centavos)), centavos)
        }
        XCTAssertEqual(Centavos.reais(de: 12_345), Decimal(string: "123.45"))
    }

    func testDoubleSoNaFronteiraComCharts() {
        XCTAssertEqual(Centavos.double(de: 1990), 19.9, accuracy: 0.0000001)
    }

    func testDigitosDigitadosSaoOsCentavos() {
        XCTAssertEqual(Centavos.de(digitos: "R$ 12,34", maximoDeDigitos: 10), 1234)
        XCTAssertEqual(Centavos.de(digitos: "", maximoDeDigitos: 10), 0)
        XCTAssertEqual(Centavos.de(digitos: "123456789012", maximoDeDigitos: 9), 123_456_789)
    }

    func testFracaoPercentualArredondaParaOCentavo() {
        XCTAssertEqual(Centavos.fracao(300_000, percentual: 50), 150_000)
        XCTAssertEqual(Centavos.fracao(300_000, percentual: 25), 75_000)
        XCTAssertEqual(Centavos.fracao(999, percentual: 10), 100)
        XCTAssertEqual(Centavos.fracao(1005, percentual: 30), 302)
    }

    func testArredondarParaMultiplosDeCincoReais() {
        XCTAssertEqual(Centavos.arredondar(12_400, multiploDe: 500), 12_500)
        XCTAssertEqual(Centavos.arredondar(12_249, multiploDe: 500), 12_000)
        XCTAssertEqual(Centavos.arredondar(12_250, multiploDe: 500), 12_500)
        XCTAssertEqual(Centavos.arredondar(-300, multiploDe: 500), 0)
    }

    func testDividirEProporcaoNaoPerdemCentavos() {
        XCTAssertEqual(Centavos.dividir(1000, por: 3), 333)
        XCTAssertEqual(Centavos.dividir(1001, por: 2), 501)
        XCTAssertEqual(Centavos.dividir(1000, por: 0), 0)
        XCTAssertEqual(Centavos.proporcao(10_000, parte: 1, de: 3), 3333)
        XCTAssertEqual(Centavos.proporcao(10_000, parte: 5, de: 0), 0)
    }

    func testRazaoDeTotalNaoPositivoEhZero() {
        XCTAssertEqual(Centavos.razao(50, de: 200), 0.25, accuracy: 0.0000001)
        XCTAssertEqual(Centavos.razao(50, de: 0), 0)
    }

    func testFormatacaoEmCentavos() {
        let ptBR = Locale(identifier: "pt_BR")
        XCTAssertEqual(semEspacoDuro(Centavos.formatado(123_450, locale: ptBR)), "R$ 1.234,50")
        XCTAssertEqual(semEspacoDuro(Centavos.formatado(5, locale: ptBR)), "R$ 0,05")
        XCTAssertEqual(semEspacoDuro(Centavos.formatado(-320, locale: ptBR)), "-R$ 3,20")
        XCTAssertEqual(semEspacoDuro(Centavos.formatado(0, locale: ptBR)), "R$ 0,00")
    }
}
