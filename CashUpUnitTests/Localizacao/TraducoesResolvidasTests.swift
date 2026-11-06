import XCTest
@testable import CashUp

/// Resolve textos reais do app em en e es (e confere o pt-BR) sem depender do idioma do simulador:
/// `LocalizedStringResource.locale` escolhe o idioma da busca no bundle do app.
@MainActor
final class TraducoesResolvidasTests: XCTestCase {
    private let pt = Locale(identifier: "pt_BR")
    private let en = Locale(identifier: "en")
    private let es = Locale(identifier: "es")

    private func resolver(_ recurso: LocalizedStringResource, _ locale: Locale) -> String {
        var r = recurso
        r.locale = locale
        return String(localized: r)
    }

    // MARK: - CashUpDomainError

    private var todosOsErros: [CashUpDomainError] {
        [
            .valorInvalido, .categoriaAusente, .categoriaInvalidaParaReceita, .categoriaInvalidaParaDespesa,
            .dataMuitoDistante, .dataFimAnteriorAoInicio, .dataFimMuitoDistante, .transacaoNaoEncontrada,
            .categoriaEmUso(quantidadeTransacoes: 3), .subcategoriaEmUso(quantidadeTransacoes: 3),
            .nomeInvalido, .nomeDuplicado("Mercado"), .categoriaProtegida, .subcategoriaProtegida,
            .corEmUso, .corCategoriaBaseProtegida, .persistencia("disco cheio")
        ]
    }

    func testMensagensDeErroResolvemEmEnEEs() {
        for erro in todosOsErros {
            let ptTexto = resolver(erro.mensagem, pt)
            let enTexto = resolver(erro.mensagem, en)
            let esTexto = resolver(erro.mensagem, es)
            XCTAssertNotEqual(enTexto, ptTexto, "en sem tradução: \(ptTexto)")
            XCTAssertNotEqual(esTexto, ptTexto, "es sem tradução: \(ptTexto)")
            for texto in [ptTexto, enTexto, esTexto] {
                XCTAssertFalse(texto.contains("%"), "placeholder sem substituir: \(texto)")
                XCTAssertFalse(texto.contains("(s)") || texto.contains("(ões)"), "plural sem variação: \(texto)")
            }
        }
    }

    func testMensagemDeErroInterpolaEUsaPlural() {
        let um = CashUpDomainError.categoriaEmUso(quantidadeTransacoes: 1)
        let tres = CashUpDomainError.categoriaEmUso(quantidadeTransacoes: 3)

        XCTAssertEqual(resolver(um.mensagem, pt), "Esta categoria possui 1 transação e não pode ser apagada.")
        XCTAssertEqual(resolver(tres.mensagem, pt), "Esta categoria possui 3 transações e não pode ser apagada.")
        XCTAssertEqual(resolver(um.mensagem, en), "This category has 1 transaction and cannot be deleted.")
        XCTAssertEqual(resolver(tres.mensagem, en), "This category has 3 transactions and cannot be deleted.")
        XCTAssertEqual(resolver(um.mensagem, es), "Esta categoría tiene 1 transacción y no se puede eliminar.")
        XCTAssertEqual(resolver(tres.mensagem, es), "Esta categoría tiene 3 transacciones y no se puede eliminar.")

        let duplicado = CashUpDomainError.nomeDuplicado("Mercado")
        XCTAssertEqual(resolver(duplicado.mensagem, en), "A category or subcategory named \"Mercado\" already exists.")
        XCTAssertEqual(resolver(duplicado.mensagem, es), "Ya existe una categoría o subcategoría con el nombre \"Mercado\".")
    }

    func testErrorDescriptionUsaAMensagemLocalizada() {
        for erro in todosOsErros {
            XCTAssertEqual(erro.errorDescription, String(localized: erro.mensagem))
        }
    }

    // MARK: - Registrar despesa/receita

    func testTituloDeRegistrarDespesaEReceitaEmCadaIdioma() {
        let sut = AddTransactionViewModel()

        sut.selectedTransactionType = 0
        XCTAssertEqual(resolver(sut.tituloResource, pt), "Registrar Despesa")
        XCTAssertEqual(resolver(sut.tituloResource, en), "Record Expense")
        XCTAssertEqual(resolver(sut.tituloResource, es), "Registrar Gasto")

        sut.selectedTransactionType = 1
        XCTAssertEqual(resolver(sut.tituloResource, pt), "Registrar Receita")
        XCTAssertEqual(resolver(sut.tituloResource, en), "Record Income")
        XCTAssertEqual(resolver(sut.tituloResource, es), "Registrar Ingreso")
    }

    // MARK: - Dicas

    func testCategoriasDeDicaResolvemEmCadaIdioma() {
        XCTAssertEqual(TipCategory.allCases.map { resolver($0.tituloResource, pt) },
                       ["Orçamento", "Economia", "Hábitos", "Renda & Investimento"])
        XCTAssertEqual(TipCategory.allCases.map { resolver($0.tituloResource, en) },
                       ["Budget", "Savings", "Habits", "Income & Investing"])
        XCTAssertEqual(TipCategory.allCases.map { resolver($0.tituloResource, es) },
                       ["Presupuesto", "Ahorro", "Hábitos", "Ingresos e Inversión"])
    }

    func testDicasSaoTraduzidasPeloRepositorio() {
        let fonte = BundledTipsRepository.fallbackTips
        let emPt = BundledTipsRepository(locale: pt).loadEducationalTips()
        let emEn = BundledTipsRepository(locale: en).loadEducationalTips()
        let emEs = BundledTipsRepository(locale: es).loadEducationalTips()

        XCTAssertEqual(emPt, fonte, "pt-BR devolve o texto-fonte")
        XCTAssertEqual(emEn.count, fonte.count)
        XCTAssertEqual(emEs.count, fonte.count)
        for (original, traduzida) in zip(fonte, emEn) {
            XCTAssertNotEqual(traduzida.title, original.title, "título sem tradução (en): \(original.title)")
            XCTAssertNotEqual(traduzida.body, original.body, "corpo sem tradução (en): \(original.title)")
            XCTAssertEqual(traduzida.id, original.id)
            XCTAssertEqual(traduzida.category, original.category)
            XCTAssertEqual(traduzida.icon, original.icon)
        }
        for (original, traduzida) in zip(fonte, emEs) {
            XCTAssertNotEqual(traduzida.title, original.title, "título sem tradução (es): \(original.title)")
            XCTAssertNotEqual(traduzida.body, original.body, "corpo sem tradução (es): \(original.title)")
        }
        XCTAssertEqual(emEn.first?.title, "The 72-Hour Rule for Impulse Buys")
        XCTAssertEqual(emEs.first?.title, "La Regla de los 3 Días para los Antojos")
    }

    // MARK: - Catálogos de categoria

    func testNomesDeCoresDaPaletaResolvemEmCadaIdioma() {
        let nomes = CategoriaPalette.coresDisponiveis.map(\.nome)
        XCTAssertEqual(nomes.map { AppLocalization.string($0, locale: en) },
                       ["Crimson Red", "Golden Yellow", "Electric Blue", "Violet Purple", "Lime Green", "Sky Cyan", "Magenta Pink", "Slate Gray"])
        XCTAssertEqual(nomes.map { AppLocalization.string($0, locale: es) },
                       ["Rojo Carmesí", "Amarillo Dorado", "Azul Eléctrico", "Morado Violeta", "Verde Lima", "Cian Celeste", "Magenta Rosado", "Gris Pizarra"])
        XCTAssertEqual(nomes.map { AppLocalization.string($0, locale: pt) }, nomes)
    }

    func testTitulosDosGruposDeSimbolosResolvemEmCadaIdioma() {
        let grupos = CategoriaSymbols.grupos
        XCTAssertEqual(grupos.map { resolver($0.titulo, en) },
                       ["Shopping & Groceries", "Home & Family", "Food & Dining", "Transportation & Travel",
                        "Health & Care", "Work & Study", "Leisure & Culture", "Finance & Goals"])
        XCTAssertEqual(grupos.map { resolver($0.titulo, es) },
                       ["Compras y Supermercado", "Hogar y Familia", "Alimentación", "Transporte y Viajes",
                        "Salud y Cuidados", "Trabajo y Estudios", "Ocio y Cultura", "Finanzas y Metas"])
    }

    func testRawValueDasOpcoesDeRepeticaoContinuaSendoOValorPersistido() {
        XCTAssertEqual(RepeatOption.allCases.map(\.rawValue),
                       ["Nunca", "Diariamente", "Semanalmente", "A cada 10 dias", "Mensalmente", "Anualmente"])
    }

    // MARK: - Plurais do planejamento (copiar para o próximo mês)

    func testCopiaDePlanejamentoUsaPluralEmCadaIdioma() {
        let um: LocalizedStringResource = "\(1) categoria(s) copiada(s) para \("novembro de 2026")."
        let duas: LocalizedStringResource = "\(2) categoria(s) copiada(s) para \("novembro de 2026")."

        XCTAssertEqual(resolver(um, pt), "1 categoria copiada para novembro de 2026.")
        XCTAssertEqual(resolver(duas, pt), "2 categorias copiadas para novembro de 2026.")
        XCTAssertEqual(resolver(um, en), "1 category copied to novembro de 2026.")
        XCTAssertEqual(resolver(duas, en), "2 categories copied to novembro de 2026.")
        XCTAssertEqual(resolver(um, es), "1 categoría copiada a novembro de 2026.")
        XCTAssertEqual(resolver(duas, es), "2 categorías copiadas a novembro de 2026.")
    }

    func testContadorDeAlertasUsaPlural() {
        let um: LocalizedStringResource = "\(1) alerta(s)"
        let tres: LocalizedStringResource = "\(3) alerta(s)"
        XCTAssertEqual(resolver(um, pt), "1 alerta")
        XCTAssertEqual(resolver(tres, pt), "3 alertas")
        XCTAssertEqual(resolver(um, en), "1 alert")
        XCTAssertEqual(resolver(tres, en), "3 alerts")
    }
}
