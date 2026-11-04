import Foundation

/// Dinheiro do app é `Int64` em centavos. Este tipo concentra as conversões de/para `Decimal` e `Double`,
/// sempre com arredondamento comercial (meio para longe do zero), nunca truncando.
enum Centavos {
    /// Acima disso o `Double` perde a precisão de centavos (2^53); os valores são limitados a este teto.
    static let limite: Int64 = 9_007_199_254_740_992

    /// Converte um valor em reais (`Double` legado) em centavos.
    /// Parte da representação decimal mais curta do número (`19.9` e não `19.899999999999999`), então `19.899999` vira 1990.
    static func de(reais valor: Double) -> Int64 {
        guard valor.isFinite else { return 0 }
        let decimal = Decimal(string: "\(valor)", locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(valor)
        return de(reais: decimal)
    }

    /// Converte um valor em reais em centavos, arredondando para o centavo mais próximo.
    static func de(reais valor: Decimal) -> Int64 {
        inteiro(valor * 100)
    }

    static func reais(de centavos: Int64) -> Decimal {
        Decimal(centavos) / 100
    }

    /// Só para a fronteira com Swift Charts, que exige `Double`. Nunca some nem compare valores nesse tipo.
    static func double(de centavos: Int64) -> Double {
        Double(centavos) / 100
    }

    /// Valor digitado num campo de moeda: os dígitos são os centavos ("1234" -> 12,34).
    static func de(digitos texto: String, maximoDeDigitos: Int) -> Int64 {
        let digitos = texto.filter { $0.isASCII && $0.isNumber }
        return Int64(String(digitos.prefix(maximoDeDigitos))) ?? 0
    }

    /// `percentual` por cento de `centavos` (ex.: 25 para 25%), arredondado para o centavo mais próximo.
    static func fracao(_ centavos: Int64, percentual: Double) -> Int64 {
        let fator = Decimal(string: "\(percentual)", locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(percentual)
        return inteiro(Decimal(centavos) * fator / 100)
    }

    /// Divide `centavos` em `partes` iguais, arredondando para o centavo mais próximo.
    static func dividir(_ centavos: Int64, por partes: Int) -> Int64 {
        guard partes > 0 else { return 0 }
        return inteiro(Decimal(centavos) / Decimal(partes))
    }

    /// Fatia de `total` proporcional a `parte` dentro de `soma` (`total * parte / soma`), arredondada para o centavo mais próximo.
    static func proporcao(_ total: Int64, parte: Int64, de soma: Int64) -> Int64 {
        guard soma > 0 else { return 0 }
        return inteiro(Decimal(total) * Decimal(parte) / Decimal(soma))
    }

    /// Razão `parte / total` (0 se `total` não for positivo), para barras de progresso e percentuais.
    static func razao(_ parte: Int64, de total: Int64) -> Double {
        total > 0 ? Double(parte) / Double(total) : 0
    }

    /// Arredonda UMA vez, a partir do valor exato em centavos, para o múltiplo de `passo` centavos mais próximo (meio para longe do zero), sem passar de zero.
    /// Use no lugar de arredondar o centavo antes (`fracao`/`dividir`/`proporcao`) e o múltiplo depois: o duplo arredondamento muda o resultado perto do ponto médio.
    static func arredondar(_ exato: Decimal, multiploDe passo: Int64) -> Int64 {
        guard passo > 0 else { return max(inteiro(exato), 0) }
        let multiplos = inteiro(exato / Decimal(passo))
        let (produto, estourou) = multiplos.multipliedReportingOverflow(by: passo)
        return max(estourou ? limite : min(produto, limite), 0)
    }

    static func formatado(_ centavos: Int64, locale: Locale? = nil) -> String {
        BRLCurrencyFormatter.string(fromCentavos: centavos, locale: locale)
    }

    /// Texto em reais (`.currency(code: "BRL")`) de um valor em centavos. As views que usam `FormatStyle` devem passar por aqui:
    /// passar o `Int64` direto para `.currency` o trata como reais e mostra o valor 100 vezes maior.
    static func moedaBRL(_ centavos: Int64, locale: Locale = .autoupdatingCurrent) -> String {
        reais(de: centavos).formatted(.currency(code: "BRL").locale(locale))
    }

    /// Arredonda (meio para longe do zero) e limita ao teto.
    private static func inteiro(_ valor: Decimal) -> Int64 {
        var bruto = valor
        var arredondado = Decimal()
        NSDecimalRound(&arredondado, &bruto, 0, .plain)
        let numero = NSDecimalNumber(decimal: arredondado)
        guard numero.compare(NSDecimalNumber(value: limite)) != .orderedDescending else { return limite }
        guard numero.compare(NSDecimalNumber(value: -limite)) != .orderedAscending else { return -limite }
        return numero.int64Value
    }
}
