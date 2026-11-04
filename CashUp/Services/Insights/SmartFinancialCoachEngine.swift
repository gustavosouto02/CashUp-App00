import Foundation

final class SmartFinancialCoachEngine: InsightEngineProtocol {
    func analyze(
        month: Date,
        expenses: [DisplayableExpense],
        plannedCategories: [CategoriaPlanejadaModel],
        today: Date,
        calendar: Calendar = .current
    ) -> [FinancialInsight] {
        var results: [FinancialInsight] = []

        let despesasMes = expenses.filter { !$0.isIncome }
        let totalGasto = despesasMes.reduce(0) { $0 + $1.amountInCents }

        let totalPlanejado = plannedCategories.reduce(Int64(0)) { acc, cat in
            acc + (cat.subcategoriasPlanejadas ?? []).reduce(Int64(0)) { $0 + $1.valorPlanejadoCentavos }
        }

        guard let intervaloMes = calendar.dateInterval(of: .month, for: month) else {
            return results
        }

        let totalDiasMes = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let diaReferencia: Int
        let mesmoMes = calendar.isDate(today, equalTo: month, toGranularity: .month)

        if mesmoMes {
            diaReferencia = min(max(calendar.component(.day, from: today), 1), totalDiasMes)
        } else if today > intervaloMes.end {
            diaReferencia = totalDiasMes
        } else {
            diaReferencia = 1
        }

        let diasRestantes = max(totalDiasMes - diaReferencia, 1)

        if let burnRateInsight = avaliarBurnRate(
            totalGasto: totalGasto,
            totalPlanejado: totalPlanejado,
            diaReferencia: diaReferencia,
            totalDiasMes: totalDiasMes
        ) {
            results.append(burnRateInsight)
        }

        if let dailyBudgetInsight = avaliarDailyBudget(
            totalGasto: totalGasto,
            totalPlanejado: totalPlanejado,
            diasRestantes: diasRestantes
        ) {
            results.append(dailyBudgetInsight)
        }

        if let peakInsight = avaliarPicos(
            despesas: despesasMes,
            totalGasto: totalGasto,
            referencia: today,
            calendar: calendar
        ) {
            results.append(peakInsight)
        }

        if let weekendInsight = avaliarFimDeSemana(
            despesas: despesasMes,
            calendar: calendar
        ) {
            results.append(weekendInsight)
        }

        if let streakInsight = avaliarReforcoPositivo(
            totalGasto: totalGasto,
            totalPlanejado: totalPlanejado,
            diaReferencia: diaReferencia,
            totalDiasMes: totalDiasMes
        ) {
            results.append(streakInsight)
        }

        return results.sorted { $0.priorityScore > $1.priorityScore }
    }

    private func avaliarBurnRate(
        totalGasto: Int64,
        totalPlanejado: Int64,
        diaReferencia: Int,
        totalDiasMes: Int
    ) -> FinancialInsight? {
        guard totalPlanejado > 0, diaReferencia >= 3, totalGasto < totalPlanejado else { return nil }

        let pctGasto = Centavos.razao(totalGasto, de: totalPlanejado)
        let pctTempo = Double(diaReferencia) / Double(totalDiasMes)

        guard pctGasto >= pctTempo + 0.15 else { return nil }

        let mediaDiaria = Double(totalGasto) / Double(diaReferencia)
        let diaEsgotamento = mediaDiaria > 0 ? min(Int(Double(totalPlanejado) / mediaDiaria), totalDiasMes) : diaReferencia
        let pctInt = Int(pctGasto * 100)

        return FinancialInsight(
            title: "Dá uma segurada no gasto!",
            message: "Nesse ritmo, seu orçamento estoura por volta do dia \(max(diaEsgotamento, diaReferencia)), e o mês tem \(totalDiasMes) dias. Hora de pisar no freio!",
            severity: .perigo,
            triggerType: .burnRate,
            priorityScore: 95,
            metricLabel: "\(pctInt)% do teto consumido",
            actionLabel: "Ver Gastos"
        )
    }

    private func avaliarDailyBudget(
        totalGasto: Int64,
        totalPlanejado: Int64,
        diasRestantes: Int
    ) -> FinancialInsight? {
        guard totalPlanejado > 0 else { return nil }

        let saldoRestante = totalPlanejado - totalGasto

        if saldoRestante <= 0 {
            let estouro = abs(saldoRestante)
            let formattedEstouro = BRLCurrencyFormatter.string(fromCentavos: estouro)
            return FinancialInsight(
                title: "Teto Orçamentário Ultrapassado",
                message: "Você já ultrapassou seu orçamento planejado em \(formattedEstouro). Qualquer novo gasto vai aumentar o vermelho este mês!",
                severity: .perigo,
                triggerType: .dailyBudget,
                priorityScore: 98,
                metricLabel: "Estourado",
                actionLabel: "Revisar Teto"
            )
        }

        let limiteDiario = Centavos.dividir(saldoRestante, por: diasRestantes)
        let formattedLimite = BRLCurrencyFormatter.string(fromCentavos: limiteDiario)

        if limiteDiario < 2_500 {
            return FinancialInsight(
                title: "Orçamento Diário Apertado",
                message: "Para não fechar no vermelho, você tem no máximo \(formattedLimite) por dia pelos próximos \(diasRestantes) dias.",
                severity: .atencao,
                triggerType: .dailyBudget,
                priorityScore: 86,
                metricLabel: "\(formattedLimite)/dia",
                actionLabel: "Ver Limites"
            )
        } else {
            return FinancialInsight(
                title: "Meta de Gasto Diário",
                message: "Para fechar o mês no azul, sua meta é gastar no máximo \(formattedLimite) por dia até o encerramento do mês.",
                severity: .informativo,
                triggerType: .dailyBudget,
                priorityScore: 72,
                metricLabel: "\(formattedLimite)/dia",
                actionLabel: "Acompanhar"
            )
        }
    }

    private func avaliarPicos(
        despesas: [DisplayableExpense],
        totalGasto: Int64,
        referencia: Date,
        calendar: Calendar
    ) -> FinancialInsight? {
        guard despesas.count >= 3, totalGasto > 0 else { return nil }

        let seteDiasAtras = calendar.date(byAdding: .day, value: -7, to: referencia) ?? referencia

        let despesasRecentes = despesas.filter { $0.date >= seteDiasAtras }
        // amount >= 2,5 * média  <=>  amount * 2 * quantidade >= 5 * total (sem dividir, para não perder centavos)
        let quantidade = Int64(despesas.count)
        let candidatas = despesasRecentes.filter { $0.amountInCents * 2 * quantidade >= totalGasto * 5 && $0.amountInCents >= 8_000 }

        guard let pico = candidatas.max(by: { $0.amountInCents < $1.amountInCents }) else { return nil }

        let desc = pico.expenseDescription.isEmpty ? "uma compra recente" : pico.expenseDescription
        let formattedAmount = BRLCurrencyFormatter.string(fromCentavos: pico.amountInCents)
        return FinancialInsight(
            title: "Gasto Fora da Curva",
            message: "Detectamos um pico: \(desc) custou \(formattedAmount). Foi uma compra planejada ou deu uma escapada do plano?",
            severity: .atencao,
            triggerType: .anomalyPeak,
            priorityScore: 82,
            metricLabel: formattedAmount,
            actionLabel: "Ver Transação"
        )
    }

    private func avaliarFimDeSemana(
        despesas: [DisplayableExpense],
        calendar: Calendar
    ) -> FinancialInsight? {
        guard despesas.count >= 4 else { return nil }

        var totalFimDeSemana: Int64 = 0
        var totalGeral: Int64 = 0

        for item in despesas {
            totalGeral += item.amountInCents
            let weekday = calendar.component(.weekday, from: item.date)
            if weekday == 1 || weekday == 7 {
                totalFimDeSemana += item.amountInCents
            }
        }

        guard totalGeral > 0, totalFimDeSemana >= 10_000 else { return nil }

        let pctFDS = Centavos.razao(totalFimDeSemana, de: totalGeral)
        guard pctFDS >= 0.50 else { return nil }

        let pctInt = Int(pctFDS * 100)
        return FinancialInsight(
            title: "Alerta de Final de Semana",
            message: "\(pctInt)% do seu dinheiro foi gasto no sábado e domingo. Dá uma segurada no combo delivery, passeios e saidinhas para não desbalancear a semana!",
            severity: .atencao,
            triggerType: .weekendSpender,
            priorityScore: 80,
            metricLabel: "\(pctInt)% no FDS",
            actionLabel: "Analisar FDS"
        )
    }

    private func avaliarReforcoPositivo(
        totalGasto: Int64,
        totalPlanejado: Int64,
        diaReferencia: Int,
        totalDiasMes: Int
    ) -> FinancialInsight? {
        guard totalPlanejado > 0 else { return nil }

        let pctGasto = Centavos.razao(totalGasto, de: totalPlanejado)
        let pctTempo = Double(diaReferencia) / Double(totalDiasMes)

        if totalGasto == 0 {
            return FinancialInsight(
                title: "Mês Limpo até Aqui",
                message: "Nenhum gasto registrado ainda este mês. Excelente oportunidade para começar poupando forte!",
                severity: .positivo,
                triggerType: .positiveStreak,
                priorityScore: 60,
                metricLabel: "Zero gastos",
                actionLabel: "Planejar"
            )
        }

        if pctGasto <= (pctTempo * 0.80) {
            return FinancialInsight(
                title: "Mandou bem demais!",
                message: "Você está economizando firme e seus gastos estão bem abaixo do teto previsto para essa altura do mês. Continue mantendo o foco!",
                severity: .positivo,
                triggerType: .positiveStreak,
                priorityScore: 68,
                metricLabel: "No ritmo ideal",
                actionLabel: "Comemorar"
            )
        }

        return nil
    }
}
