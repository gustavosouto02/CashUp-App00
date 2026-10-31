//
//  ExpenseCalculationProtocol.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 22/05/25.
//

import Foundation

@MainActor
protocol ExpenseCalculation {
    func calcularTotalGastoEmCategoriasPlanejadas(paraMes mes: Date, categoriasPlanejadas: [CategoriaPlanejadaModel]) -> Int64
    func calcularTotalGastoParaCategoria(_ categoriaPlanejada: CategoriaPlanejadaModel, paraMes mes: Date) -> Int64
    func calcularTotalGastoParaSubcategoria(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel, paraMes mes: Date) -> Int64
}
