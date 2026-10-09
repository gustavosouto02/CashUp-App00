import Foundation

enum CashUpDomainError: LocalizedError, Equatable {
    case valorInvalido
    case categoriaAusente
    case dataMuitoDistante
    case dataFimAnteriorAoInicio
    case dataFimMuitoDistante
    case transacaoNaoEncontrada
    case categoriaEmUso(quantidadeTransacoes: Int)
    case persistencia(String)

    var errorDescription: String? {
        switch self {
        case .valorInvalido:
            return "Informe um valor maior que zero."
        case .categoriaAusente:
            return "Selecione uma categoria e uma subcategoria."
        case .dataMuitoDistante:
            return "A data não pode ultrapassar 100 anos no futuro."
        case .dataFimAnteriorAoInicio:
            return "A data final da repetição não pode ser anterior à data da transação."
        case .dataFimMuitoDistante:
            return "A repetição não pode ultrapassar \(RepetitionData.limiteMaximoAnos) anos."
        case .transacaoNaoEncontrada:
            return "Transação não encontrada."
        case .categoriaEmUso(let quantidade):
            return "Esta categoria possui \(quantidade) transação(ões) e não pode ser apagada."
        case .persistencia(let detalhe):
            return "Não foi possível salvar: \(detalhe)"
        }
    }
}
