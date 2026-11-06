import XCTest

/// Impede a volta do problema "texto em pt-BR que chega como `String` e nunca é traduzido".
///
/// Varre o código-fonte do app e falha quando um literal que parece português (acentos ou palavras comuns)
/// aparece fora de um contexto que localiza: `String(localized:)`, `Text`, `Button`, `LocalizedStringKey`,
/// `LocalizedStringResource`, logs etc. O scan é conservador de propósito: só olha literais com cara de frase
/// (acentuados ou com palavras funcionais) e tem allowlists explícitas e justificadas abaixo.
final class ScanLiteraisPortuguesesTests: XCTestCase {

    // MARK: - Allowlists (cada entrada precisa de justificativa)

    /// Arquivos inteiros fora do scan.
    private static let arquivosPermitidos: [String: String] = [
        "Services/Persistencia/SeedService.swift":
            "Nomes persistidos do seed: são chaves do catálogo, traduzidas na gravação via AppLocalization.string (PR #38).",
        "Services/Persistencia/StoreLocationMigrator.swift":
            "Mensagens de erro só vão para log (CashUpApp mostra um aviso fixo e localizado).",
        "Repositories/Dicas/BundledTipsRepository.swift":
            "Texto-fonte pt-BR das dicas: é a chave do catálogo, traduzida por AppLocalization.string no repositório.",
        "Views/Categoria/Componentes/CategoriaPalette.swift":
            "Nomes pt-BR das cores: chaves do catálogo, exibidas por CategoriaCor.nomeExibicao.",
    ]

    /// Literais isolados que não são texto de interface (arquivo|texto).
    private static let literaisPermitidos: [String: String] = [
        "Views/Categoria/CategoriaEditorViewModel.swift|Diversos":
            "Nome da subcategoria padrão gravada no banco e usado para achar o destino do remanejo: dado persistido, não se traduz.",
        "Services/Notifications/LocalNotificationService.swift|CashUp": "Nome da marca no título da notificação.",
    ]

    /// Funções/inicializadores cujo parâmetro de texto é `LocalizedStringKey`/`LocalizedStringResource`
    /// (o compilador extrai o literal para o catálogo).
    private static let chamadasPermitidas: [String: String] = [
        "recurringScopeDialog": "titulo: LocalizedStringKey",
        "linhaBarra": "titulo: LocalizedStringKey (FiftyThirtyTwentyCard)",
        "itemLinha": "titulo/subtitulo: LocalizedStringKey (PrivacySecurityCard)",
        "resumoItem": "label: LocalizedStringKey (ExpensesResumoView)",
        "CategoriaSymbolGroup": "titulo: LocalizedStringResource",
        "OnboardingPage": "titulo/mensagem: LocalizedStringResource",
        "AppLocalization.string": "o literal é a chave de busca no catálogo",
    ]

    /// Chamadas de interface/log em que o literal é localizado ou nunca chega ao usuário.
    private static let prefixosSeguros: [String] = [
        "Text", "Button", "Label", "Section", "Toggle", "Picker", "DatePicker", "TextField", "SecureField",
        "NavigationLink", "Menu", "Link", "ProgressView", "LabeledContent", "Stepper", "Slider", "GroupBox",
        "navigationTitle", "alert", "confirmationDialog", "accessibilityLabel", "accessibilityHint",
        "accessibilityValue", "accessibilityIdentifier", "help", "value", "Image", "String(localized)",
        "LocalizedStringKey", "LocalizedStringResource", "NSLocalizedString", "fatalError", "assertionFailure",
        "precondition", "preconditionFailure", "print", "debugPrint", "NSLog", "Preview"
    ]

    // MARK: - Teste principal

    func testNaoHaLiteralPortuguesComoStringForaDeLocalizacao() throws {
        let appDir = CatalogoLocalizacao.raiz.appendingPathComponent("CashUp")
        let arquivos = try XCTUnwrap(FileManager.default.enumerator(at: appDir, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThan(arquivos.count, 50, "o scan não encontrou o código do app")

        // Um literal igual a uma chave do catálogo é texto de interface, mesmo sem acento (ex.: "Registrar Despesa").
        let chaves = Set(try CatalogoLocalizacao.carregarLocalizable().keys.filter { $0.count >= 3 && $0.contains(where: \.isLetter) })

        var violacoes: [String] = []
        for url in arquivos.sorted(by: { $0.path < $1.path }) {
            let relativo = String(url.path.dropFirst(appDir.path.count + 1))
            if Self.arquivosPermitidos[relativo] != nil { continue }
            let fonte = try String(contentsOf: url, encoding: .utf8)
            for achado in Self.achados(em: fonte, chavesDoCatalogo: chaves) {
                if Self.literaisPermitidos["\(relativo)|\(achado.texto)"] != nil { continue }
                violacoes.append("\(relativo):\(achado.linha): \"\(achado.texto)\"")
            }
        }
        XCTAssertTrue(violacoes.isEmpty, """
        Literal em português fora de String(localized:)/Text/LocalizedStringKey. Use String(localized: "..."), troque o tipo \
        do parâmetro por LocalizedStringKey/LocalizedStringResource ou, se não for texto de usuário, justifique na allowlist:
        \(violacoes.joined(separator: "\n"))
        """)
    }

    // MARK: - Controle negativo: o scanner precisa enxergar os casos ruins e aceitar os bons

    func testScannerDetectaOsCasosRuinsEAceitaOsBons() {
        let ruim = """
        var titulo: String {
            return "Ação não permitida"
        }
        func mensagem() -> String { cond ? "Não encontrado" : "Já existe" }
        let erro = "Falha ao salvar o arquivo"
        """
        XCTAssertEqual(Self.achados(em: ruim).map(\.linha), [2, 4, 4, 5])

        let semAcento = "func titulo() -> String { cond ? \"Registrar Despesa\" : \"Registrar Receita\" }"
        XCTAssertTrue(Self.achados(em: semAcento).isEmpty, "sem pista de português e sem o catálogo, passa")
        XCTAssertEqual(Self.achados(em: semAcento, chavesDoCatalogo: ["Registrar Despesa"]).count, 1)

        let bom = """
        var titulo: String { String(localized: "Ação não permitida") }
        var chave: LocalizedStringKey { "Ação não permitida" }
        var recurso: LocalizedStringResource { cond ? "Ação não permitida" : "Já existe" }
        let v = Text("Falha ao salvar o arquivo")
        CashUpLogger.persistence.error("Falha ao salvar: \\(erro)")
        // return "Ação não permitida"
        /// = "Já existe uma categoria"
        case ocupado = "Estilo de Vida"
        let interp = String(localized: "Total \\(itens.joined(separator: ", ")) de itens")
        """
        XCTAssertTrue(Self.achados(em: bom).isEmpty, "\(Self.achados(em: bom))")
    }

    // MARK: - Implementação do scan

    struct Achado { let linha: Int; let texto: String }

    private struct Literal {
        let texto: String
        let linha: Int
        /// Nomes das chamadas que envolvem o literal, da mais externa para a mais interna.
        let chamadas: [String]
    }

    static func achados(em fonte: String, chavesDoCatalogo: Set<String> = []) -> [Achado] {
        let linhas = fonte.components(separatedBy: "\n")
        return literais(em: fonte).compactMap { lit in
            guard pareceTextoPortugues(lit.texto) || chavesDoCatalogo.contains(lit.texto) else { return nil }
            if lit.chamadas.contains(where: ehChamadaSegura) { return nil }
            let linhaDoLiteral = linhas[lit.linha - 1]
            let aparado = linhaDoLiteral.trimmingCharacters(in: .whitespaces)
            // Valores brutos de enum (`case x = "..."`) são identificadores, não texto exibido.
            if aparado.hasPrefix("case ") && aparado.contains("= \"") { return nil }
            let marcadores = ["LocalizedStringKey", "LocalizedStringResource", "String(localized"]
            if marcadores.contains(where: linhaDoLiteral.contains) { return nil }
            if let declaracao = declaracaoAnterior(a: lit.linha, em: linhas),
               marcadores.contains(where: declaracao.contains) { return nil }
            return Achado(linha: lit.linha, texto: lit.texto)
        }
    }

    private static func ehChamadaSegura(_ nome: String) -> Bool {
        if chamadasPermitidas.keys.contains(where: { nome == $0 || nome.hasSuffix("." + $0) }) { return true }
        if nome.lowercased().contains("logger") { return true }
        let ultimo = nome.split(separator: ".").last.map(String.init) ?? nome
        return prefixosSeguros.contains(nome) || prefixosSeguros.contains(ultimo)
    }

    /// Última linha de declaração (`var`/`func`/`let`) antes do literal, para aceitar `return "..."` em
    /// propriedades do tipo `LocalizedStringKey`/`LocalizedStringResource`.
    private static func declaracaoAnterior(a linha: Int, em linhas: [String]) -> String? {
        let padrao = try! NSRegularExpression(pattern: #"^\s*(?:@\w+\s+)*(?:(?:private|fileprivate|internal|public|static|final|override|mutating)\s+)*(?:var|func|let|init)\b"#)
        var i = linha - 1
        while i >= 0 {
            let l = linhas[i]
            if padrao.firstMatch(in: l, range: NSRange(l.startIndex..., in: l)) != nil { return l }
            i -= 1
        }
        return nil
    }

    private static let acentos = CharacterSet(charactersIn: "áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ")
    private static let palavrasFuncionais: Set<String> = [
        "de", "do", "da", "dos", "das", "que", "não", "para", "com", "uma", "seu", "sua", "seus", "suas",
        "você", "este", "esta", "esse", "essa", "nenhum", "nenhuma", "já", "pelo", "pela", "foi", "são", "ao"
    ]

    /// Conservador: precisa ter cara de frase (espaço) ou acento, e uma pista clara de português.
    static func pareceTextoPortugues(_ texto: String) -> Bool {
        let semInterpolacao = texto.replacingOccurrences(of: #"\\\(\)"#, with: " ", options: .regularExpression)
        if semInterpolacao.unicodeScalars.contains(where: { acentos.contains($0) }) { return true }
        guard semInterpolacao.contains(" ") else { return false }
        let palavras = semInterpolacao.lowercased().split { !$0.isLetter }.map(String.init)
        return palavras.contains(where: palavrasFuncionais.contains)
    }

    // MARK: Tokenizador mínimo de Swift (literais, comentários, pilha de chamadas)

    private static func literais(em fonte: String) -> [Literal] {
        let c = Array(fonte)
        var i = 0
        var linha = 1
        var pilha: [String] = []        // nome da chamada de cada delimitador aberto ("" para blocos/colchetes)
        var resultado: [Literal] = []

        func chamadasAtuais() -> [String] { pilha.filter { !$0.isEmpty } }

        func lerString() {
            // posição em `"` de abertura
            let linhaInicial = linha
            if i + 2 < c.count, c[i + 1] == "\"", c[i + 2] == "\"" {      // """ multilinha
                i += 3
                var texto = ""
                while i < c.count {
                    if c[i] == "\"", i + 2 < c.count, c[i + 1] == "\"", c[i + 2] == "\"" { i += 3; break }
                    if c[i] == "\n" { linha += 1 }
                    texto.append(c[i]); i += 1
                }
                resultado.append(Literal(texto: texto, linha: linhaInicial, chamadas: chamadasAtuais()))
                return
            }
            i += 1
            var texto = ""
            while i < c.count, c[i] != "\"", c[i] != "\n" {
                if c[i] == "\\", i + 1 < c.count {
                    if c[i + 1] == "(" {
                        // interpolação: varre código até o parêntese correspondente
                        texto += "\\()"
                        i += 2
                        var profundidade = 1
                        let base = pilha.count
                        pilha.append("")
                        while i < c.count, profundidade > 0 {
                            switch c[i] {
                            case "\"": lerString(); continue
                            case "(": profundidade += 1; pilha.append(nomeDaChamada(antesDe: i))
                            case ")": profundidade -= 1; if profundidade > 0 { pilha.removeLast() }
                            case "\n": linha += 1
                            default: break
                            }
                            i += 1
                        }
                        pilha.removeSubrange(base...)
                        continue
                    }
                    texto.append(c[i + 1]); i += 2
                    continue
                }
                texto.append(c[i]); i += 1
            }
            i += 1 // fecha aspas
            resultado.append(Literal(texto: texto, linha: linhaInicial, chamadas: chamadasAtuais()))
        }

        func nomeDaChamada(antesDe indice: Int) -> String {
            var j = indice - 1
            while j >= 0, c[j] == " " { j -= 1 }
            var nome = ""
            while j >= 0, c[j].isLetter || c[j].isNumber || c[j] == "_" || c[j] == "." {
                nome.insert(c[j], at: nome.startIndex); j -= 1
            }
            if j >= 0, c[j] == "#" { nome.insert("#", at: nome.startIndex) }
            nome = nome.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            if nome == "String" {
                // String(localized: ...) localiza; String(format:), String(x) não.
                var k = indice + 1
                while k < c.count, c[k] == " " || c[k] == "\n" { k += 1 }
                let resto = String(c[k..<min(k + 10, c.count)])
                if resto.hasPrefix("localized") { return "String(localized)" }
            }
            return nome
        }

        while i < c.count {
            let ch = c[i]
            if ch == "\n" { linha += 1; i += 1; continue }
            if ch == "/", i + 1 < c.count, c[i + 1] == "/" {            // comentário de linha
                while i < c.count, c[i] != "\n" { i += 1 }
                continue
            }
            if ch == "/", i + 1 < c.count, c[i + 1] == "*" {            // comentário de bloco
                i += 2
                while i + 1 < c.count, !(c[i] == "*" && c[i + 1] == "/") {
                    if c[i] == "\n" { linha += 1 }
                    i += 1
                }
                i += 2
                continue
            }
            if ch == "\"" { lerString(); continue }
            switch ch {
            case "(": pilha.append(nomeDaChamada(antesDe: i))
            case "[", "{": pilha.append("")
            case ")", "]", "}": if !pilha.isEmpty { pilha.removeLast() }
            default: break
            }
            i += 1
        }
        return resultado
    }
}
