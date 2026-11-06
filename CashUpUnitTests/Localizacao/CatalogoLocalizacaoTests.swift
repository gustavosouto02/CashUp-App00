import XCTest
@testable import CashUp

/// Contrato do `Localizable.xcstrings`: todo texto tem pt-BR, en e es, com os mesmos placeholders, e nada fica `stale`.
final class CatalogoLocalizacaoTests: XCTestCase {
    private func carregar() throws -> [String: CatalogoLocalizacao.Entrada] {
        try CatalogoLocalizacao.carregarLocalizable()
    }

    func testToda_EntradaTemPtEnEsPreenchidos() throws {
        var problemas: [String] = []
        for (chave, entrada) in try carregar() where !chave.isEmpty {
            for idioma in CatalogoLocalizacao.idiomas {
                let valores = entrada.valores[idioma] ?? []
                if valores.isEmpty || valores.contains(where: { $0.isEmpty }) {
                    problemas.append("\(idioma) ausente/vazio: \(chave)")
                }
            }
        }
        XCTAssertTrue(problemas.isEmpty, problemas.sorted().joined(separator: "\n"))
    }

    func testPlaceholdersSaoOsMesmosEmTodosOsIdiomas() throws {
        var problemas: [String] = []
        for (chave, entrada) in try carregar() where !chave.isEmpty {
            let esperados = CatalogoLocalizacao.placeholders(em: chave).tipos.sorted()
            for (idioma, valores) in entrada.valores {
                for valor in valores {
                    let (tipos, posicoesValidas) = CatalogoLocalizacao.placeholders(em: valor)
                    if tipos.sorted() != esperados || !posicoesValidas {
                        problemas.append("\(idioma) '\(valor)' diverge da chave '\(chave)'")
                    }
                }
            }
        }
        XCTAssertTrue(problemas.isEmpty, problemas.sorted().joined(separator: "\n"))
    }

    func testNenhumaEntradaFicaStale() throws {
        let stale = try carregar().values.filter { $0.extractionState == "stale" }.map(\.chave).sorted()
        XCTAssertTrue(
            stale.isEmpty,
            "Chave sem uso no código: apague do catálogo ou, se for chave dinâmica, marque como manual:\n" + stale.joined(separator: "\n")
        )
    }

    func testChavesDinamicasEstaoNoCatalogo() throws {
        let catalogo = try carregar()
        var esperadas: Set<String> = []

        // Nomes do seed: SeedService os resolve com AppLocalization.string (chave dinâmica).
        for categoria in SeedCatalogo.categorias {
            esperadas.insert(categoria.nome)
            categoria.subcategorias.forEach { esperadas.insert($0.nome) }
        }
        // Nomes de cores da paleta: CategoriaCor.nomeExibicao.
        CategoriaPalette.coresDisponiveis.forEach { esperadas.insert($0.nome) }
        // Dicas: tips.json e o fallback (título, corpo e tag).
        for tip in BundledTipsRepository.fallbackTips {
            [tip.title, tip.body, tip.tag].forEach { esperadas.insert($0) }
        }

        var problemas: [String] = []
        for chave in esperadas.sorted() {
            guard let entrada = catalogo[chave] else {
                problemas.append("ausente do catálogo: \(chave)")
                continue
            }
            for idioma in ["en", "es"] where (entrada.valores[idioma] ?? []).allSatisfy({ $0.isEmpty }) {
                problemas.append("\(idioma) vazio: \(chave)")
            }
            if entrada.extractionState == "stale" { problemas.append("stale: \(chave)") }
        }
        XCTAssertTrue(problemas.isEmpty, problemas.joined(separator: "\n"))
    }

    func testInfoPlistTemFaceIDEmTodosOsIdiomas() throws {
        let url = CatalogoLocalizacao.raiz.appendingPathComponent("CashUp/Resources/InfoPlist.xcstrings")
        let entrada = try XCTUnwrap(CatalogoLocalizacao.carregar(url)["NSFaceIDUsageDescription"])
        for idioma in CatalogoLocalizacao.idiomas {
            XCTAssertFalse((entrada.valores[idioma] ?? [""]).contains(""), "NSFaceIDUsageDescription sem \(idioma)")
        }
    }

    func testTipsJsonEspelhaOFallback() throws {
        let url = CatalogoLocalizacao.raiz.appendingPathComponent("CashUp/Resources/tips.json")
        let doJSON = try JSONDecoder().decode([Tip].self, from: Data(contentsOf: url))
        XCTAssertEqual(doJSON, BundledTipsRepository.fallbackTips, "tips.json e BundledTipsRepository.fallbackTips devem ter o mesmo conteúdo")
    }
}
