import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class ContaRepositoryUnitTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: SwiftDataContaRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try CashUpPersistence.makeContainer(inMemory: true)
        context = ModelContext(container)
        sut = SwiftDataContaRepository(context: context)
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
        container = nil
    }

    func testStoreVazioNaoTemContas() throws {
        XCTAssertTrue(try sut.fetchContas().isEmpty)
        XCTAssertNil(try sut.fetchConta(id: SeedIDs.idContaCarteira))
    }

    func testContaPadraoCriaACarteiraQuandoNaoHaContas() throws {
        let conta = try sut.contaPadrao()
        try sut.save()

        XCTAssertEqual(conta.id, SeedIDs.idContaCarteira)
        XCTAssertEqual(conta.nome, "Carteira")
        XCTAssertEqual(conta.tipo, .carteira)
        XCTAssertEqual(try sut.fetchContas().count, 1)
    }

    func testContaPadraoNaoDuplicaACarteira() throws {
        let primeira = try sut.contaPadrao()
        let segunda = try sut.contaPadrao()
        try sut.save()
        let terceira = try sut.contaPadrao()

        XCTAssertTrue(primeira === segunda)
        XCTAssertTrue(primeira === terceira)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ContaModel>()), 1)
    }

    func testContaPadraoReaproveitaACarteiraExistente() throws {
        let carteira = ContaModel(id: SeedIDs.idContaCarteira, nome: "Carteira", saldoInicialCentavos: 5000)
        sut.insert(ContaModel(nome: "Banco", tipo: .contaCorrente, ordem: 0))
        sut.insert(carteira)
        try sut.save()

        let padrao = try sut.contaPadrao()

        XCTAssertTrue(padrao === carteira)
        XCTAssertEqual(padrao.saldoInicialCentavos, 5000)
        XCTAssertEqual(try sut.fetchContas().count, 2)
    }

    func testContaPadraoSemCarteiraUsaAPrimeiraConta() throws {
        sut.insert(ContaModel(nome: "Cartão", tipo: .cartaoCredito, ordem: 2))
        sut.insert(ContaModel(nome: "Banco", tipo: .contaCorrente, ordem: 1))
        try sut.save()

        let padrao = try sut.contaPadrao()

        XCTAssertEqual(padrao.nome, "Banco")
        XCTAssertEqual(try sut.fetchContas().count, 2, "Não cria Carteira se já existe alguma conta")
    }

    func testFetchContasOrdenaPorOrdemEDepoisPorCriacao() throws {
        let antiga = ContaModel(nome: "A", ordem: 1)
        antiga.criadoEm = Date(timeIntervalSince1970: 100)
        let nova = ContaModel(nome: "B", ordem: 1)
        nova.criadoEm = Date(timeIntervalSince1970: 200)
        let primeira = ContaModel(nome: "C", ordem: 0)
        sut.insert(nova)
        sut.insert(antiga)
        sut.insert(primeira)
        try sut.save()

        XCTAssertEqual(try sut.fetchContas().map(\.nome), ["C", "A", "B"])
    }

    func testFetchContaPorId() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        sut.insert(banco)
        try sut.save()

        XCTAssertEqual(try sut.fetchConta(id: banco.id)?.nome, "Banco")
        XCTAssertNil(try sut.fetchConta(id: UUID()))
    }

    func testTipoDesconhecidoCaiParaCarteira() {
        let conta = ContaModel(nome: "X")
        conta.tipoRaw = "inexistente"
        XCTAssertEqual(conta.tipo, .carteira)

        conta.tipo = .cartaoCredito
        XCTAssertEqual(conta.tipoRaw, "cartaoCredito")
    }

    func testApagarContaAnulaAReferenciaNasTransacoes() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        let destino = ContaModel(nome: "Poupança", tipo: .contaCorrente)
        let transacao = ExpenseModel(amountInCents: 1000, expenseDescription: "Pix", conta: banco)
        let transferencia = ExpenseModel(amountInCents: 500, tipo: .transferencia, conta: banco, contaDestino: destino)
        sut.insert(banco)
        sut.insert(destino)
        context.insert(transacao)
        context.insert(transferencia)
        try sut.save()
        XCTAssertEqual(banco.transacoes?.count, 2)
        XCTAssertEqual(destino.transferenciasRecebidas?.count, 1)

        sut.delete(destino)
        sut.delete(banco)
        try sut.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExpenseModel>()), 2, "Apagar a conta não apaga a transação")
        XCTAssertNil(transacao.conta)
        XCTAssertNil(transferencia.contaDestino)
    }

    func testRollbackDescartaContaNaoSalva() throws {
        sut.insert(ContaModel(nome: "Temporária"))
        sut.rollback()
        try sut.save()

        XCTAssertTrue(try sut.fetchContas().isEmpty)
    }
}
