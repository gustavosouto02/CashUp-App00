import Foundation

enum CashUpDomainError: LocalizedError, Equatable {
    case valorInvalido
    case categoriaAusente
    case categoriaInvalidaParaReceita
    case categoriaInvalidaParaDespesa
    case dataMuitoDistante
    case dataFimAnteriorAoInicio
    case dataFimMuitoDistante
    case transacaoNaoEncontrada
    case categoriaEmUso(quantidadeTransacoes: Int)
    case nomeInvalido
    case nomeDuplicado(String)
    case categoriaProtegida
    case subcategoriaProtegida
    case corEmUso
    case corCategoriaBaseProtegida
    case persistencia(String)

    var errorDescription: String? {
        switch self {
        case .valorInvalido:
            return "Informe um valor maior que zero."
        case .categoriaAusente:
            return "Selecione uma categoria e uma subcategoria."
        case .categoriaInvalidaParaReceita:
            return "Receitas só podem usar a categoria Renda."
        case .categoriaInvalidaParaDespesa:
            return "A categoria Renda só pode ser usada em receitas."
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
        case .nomeInvalido:
            return "O nome deve conter entre 2 e 24 caracteres."
        case .nomeDuplicado(let nome):
            return "Já existe uma categoria ou subcategoria com o nome \"\(nome)\"."
        case .categoriaProtegida:
            return "A categoria Renda é protegida pelo sistema e não pode ser alterada ou apagada."
        case .subcategoriaProtegida:
            return "Esta subcategoria é essencial e não pode ser apagada."
        case .corEmUso:
            return "Esta cor já está sendo usada por outra categoria. Escolha uma cor diferente."
        case .corCategoriaBaseProtegida:
            return "A cor das categorias padrão do sistema não pode ser alterada."
        case .persistencia(let detalhe):
            return "Não foi possível salvar: \(detalhe)"
        }
    }
}
