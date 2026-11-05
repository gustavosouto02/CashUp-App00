import Foundation

/// Leitura do `Localizable.xcstrings` direto do código-fonte (via `#filePath`) para os testes de localização.
enum CatalogoLocalizacao {
    static let idiomas = ["pt-BR", "en", "es"]

    /// Raiz do repositório: `CashUpUnitTests/Localizacao/<este arquivo>` sobe três níveis.
    static let raiz: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    static var urlLocalizable: URL { raiz.appendingPathComponent("CashUp/Resources/Localizable.xcstrings") }

    struct Entrada {
        let chave: String
        let extractionState: String?
        /// Para cada idioma, todas as strings da entrada: uma (`stringUnit`) ou uma por categoria de plural.
        let valores: [String: [String]]
    }

    static func carregarLocalizable() throws -> [String: Entrada] {
        try carregar(urlLocalizable)
    }

    static func carregar(_ url: URL) throws -> [String: Entrada] {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let strings = json["strings"] as? [String: [String: Any]] ?? [:]
        var resultado: [String: Entrada] = [:]
        for (chave, corpo) in strings {
            var valores: [String: [String]] = [:]
            let locs = corpo["localizations"] as? [String: [String: Any]] ?? [:]
            for (idioma, loc) in locs {
                if let unit = loc["stringUnit"] as? [String: Any], let v = unit["value"] as? String {
                    valores[idioma] = [v]
                } else if let plural = (loc["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]] {
                    valores[idioma] = plural.values.compactMap { ($0["stringUnit"] as? [String: Any])?["value"] as? String }
                }
            }
            resultado[chave] = Entrada(chave: chave, extractionState: corpo["extractionState"] as? String, valores: valores)
        }
        return resultado
    }

    /// Tipos dos placeholders (`@`, `lld`, `f`...) em ordem, ignorando `%%`. Posições (`%1$`) devem ser uma permutação de 1...n.
    static func placeholders(em texto: String) -> (tipos: [String], posicoesValidas: Bool) {
        let semEscape = texto.replacingOccurrences(of: "%%", with: "")
        let regex = try! NSRegularExpression(pattern: #"%(?:(\d+)\$)?(?:\.\d+)?(@|lld|ld|lf|d|f)"#)
        let range = NSRange(semEscape.startIndex..., in: semEscape)
        var tipos: [String] = []
        var posicoes: [Int] = []
        for m in regex.matches(in: semEscape, range: range) {
            tipos.append(String(semEscape[Range(m.range(at: 2), in: semEscape)!]))
            if let r = Range(m.range(at: 1), in: semEscape) { posicoes.append(Int(semEscape[r])!) }
        }
        let validas = posicoes.isEmpty || posicoes.sorted() == Array(1...tipos.count)
        return (tipos, validas)
    }
}
