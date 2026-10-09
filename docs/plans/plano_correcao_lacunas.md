# Plano de Implementação: Correção de Lacunas — CashUp (Review de 08/10/2026)

**Escopo**: Corrigir, em ordem de prioridade, os 3 bugs críticos, 5 bugs médios, débitos técnicos e 8 lacunas funcionais apontados no code review da branch `develop`.  
**Domínios Alvo**: `Transacao`, `Despesas`, `Planejamento`, `Categoria`, `Biometria`, `Onboarding`, `Dicas`.  
**Padrão**: Clean MVVM + `*RepositoryProtocol` + testes em memória (`isStoredInMemoryOnly: true`) + zero comentários em `.swift`.  
**Referências**: [`template_implementation_plan.md`](template_implementation_plan.md), [`../rules/architecture.md`](../rules/architecture.md), [`../rules/business_rules.md`](../rules/business_rules.md), [`../rules/project_structure.md`](../rules/project_structure.md).

> [!IMPORTANT]
> **Política de execução de cada etapa**
> 1. Implementar na ordem exata das etapas. Uma etapa só começa quando a anterior está verde (`xcodebuild test -scheme CashUp -destination 'platform=iOS Simulator,name=iPhone 16'`).
> 2. **Ao final de cada etapa executar o bloco "Limpeza"**: apagar arquivos, funções, testes e placeholders que deixaram de ser necessários. Arquivo sem uso é apagado, nunca comentado.
> 3. Toda UI nova nasce como componente em arquivo próprio dentro de `Componentes/` do domínio. A `View` principal apenas compõe componentes e liga bindings; nenhuma lógica de negócio em `body`.
> 4. ViewModels são `@MainActor final class`, recebem dependências por `init`, expõem `@Published var errorMessage: String?` e nunca usam `print`.
> 5. O projeto usa `PBXFileSystemSynchronizedRootGroup` (Xcode 16): arquivos criados ou apagados nas pastas `CashUp/`, `CashUpUnitTests/` e `CashUpUITests/` entram ou saem do target automaticamente. Não editar `project.pbxproj` à mão, exceto para a chave de Info.plist da Etapa 5.
> 6. Git é manual: a IA não executa `git commit`.

---

## Status de Execução

| Etapa | Status | Data | Observações |
|---|---|---|---|
| 1 | ✅ Concluída | 2026-10-08 | 53 testes unitários verdes no iPhone 17 Pro (iOS 26.4). `RepeatOption` movido para `Models/RepeatOption.swift` com `nextDate(after:)`. Os dois testes dependentes de `Date()` em `RepetitionDataTestes` foram fixados em março/2026 por bloquearem o verde (antecipação da Etapa 3). |
| 2 a 10 | ⏳ Pendente | | |

---

## Sumário

| Etapa | Prioridade | Tema | Itens do review |
|---|---|---|---|
| [1](#etapa-1--críticos-recorrência-e-persistência) | 🔴 | Recorrência, loop ilimitado, erro engolido, limite de `endDate` | 🔴 x3, gap 8 |
| [2](#etapa-2--médios-regras-de-negócio) | 🟡 | Regra Renda/tipo, `paraMes` ignorado, exclusão inconsistente, texto "1 ano" | 🟡 x4 |
| [3](#etapa-3--testes-quebrados-e-vazios) | 🟡 | Teste com `Date()`, testes placeholder | 🟡 x1 |
| [4](#etapa-4--limpeza-técnica-e-performance) | 🟢 | Seed duplicado, formatters, hacks de refresh, `print`, fetches redundantes | 🟢 x3 |
| [5](#etapa-5--camada-de-repositório) | Lacuna 7 | `*RepositoryProtocol` e injeção por `init` | L-09 |
| [6](#etapa-6--biometria-face-id--touch-id) | Lacuna 1 | `LocalAuthentication`, bloqueio ao voltar do background | L-02 |
| [7](#etapa-7--onboarding) | Lacuna 2 | Tour de 3 páginas na primeira abertura | L-03 |
| [8](#etapa-8--crud-de-categorias-personalizadas) | Lacuna 4 | Criar, editar e apagar categorias e subcategorias | L-01 |
| [9](#etapa-9--edição-de-ocorrência-única-de-recorrência) | Lacuna 3 | Editar "só esta" / "esta e futuras" | gap 3 |
| [10](#etapa-10--dicas-dinâmicas) | Lacuna 6 | `Tip` + `TipsViewModel` com conteúdo em JSON | Tips |

Feedback de erro ao usuário (lacuna 5) é resolvido transversalmente: a Etapa 1 cria `CashUpDomainError` e `ErrorAlertModifier`; cada etapa seguinte adota o padrão nos ViewModels que tocar.

---

## Etapa 1 — Críticos: recorrência e persistência

**Objetivo**: nenhuma edição pode truncar ou apagar uma série; nenhum fetch pode iterar além do mês consultado; nenhum erro de gravação pode virar alerta de sucesso.

### 1.1 Arquivos

```
CashUp/
├── Models/
│   ├── CashUpDomainError.swift                       ← CRIAR
│   ├── RepetitionData.swift                          ← MODIFICAR (métodos de edição segura)
│   └── ExpenseModel.swift                            ← MODIFICAR (limite do loop)
├── Sources/Extensions/Components/
│   └── ErrorAlertModifier.swift                      ← CRIAR
├── Views/Transação/
│   ├── AddTransactionViewModel.swift                 ← MODIFICAR (edição sai da View)
│   └── AddTransactionView.swift                      ← MODIFICAR (botão só chama o VM)
└── Views/Despesas/
    └── ExpensesViewModel.swift                       ← MODIFICAR (addExpense propaga erro)
CashUpUnitTests/Transacao/
├── RepetitionDataEditingTests.swift                  ← CRIAR
├── GenerateOccurrencesBoundsTests.swift              ← CRIAR
└── AddTransactionErrorPropagationTests.swift         ← CRIAR
```

### 1.2 Erro de domínio tipado

```swift
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
        case .valorInvalido: return "Informe um valor maior que zero."
        case .categoriaAusente: return "Selecione uma categoria e uma subcategoria."
        case .dataMuitoDistante: return "A data não pode ultrapassar 100 anos no futuro."
        case .dataFimAnteriorAoInicio: return "A data final da repetição não pode ser anterior à data da transação."
        case .dataFimMuitoDistante: return "A repetição não pode ultrapassar 10 anos."
        case .transacaoNaoEncontrada: return "Transação não encontrada."
        case .categoriaEmUso(let quantidade): return "Esta categoria possui \(quantidade) transação(ões) e não pode ser apagada."
        case .persistencia(let detalhe): return "Não foi possível salvar: \(detalhe)"
        }
    }
}
```

### 1.3 `RepetitionData` com edição que preserva `excludedDates`

```swift
extension RepetitionData {
    static let limiteMaximoAnos = 10

    func atualizando(opcao: RepeatOption, dataFim: Date?) -> RepetitionData? {
        guard opcao != .nunca else { return nil }
        return RepetitionData(repeatOption: opcao, endDate: dataFim, excludedDates: excludedDates)
    }

    static func validar(dataFim: Date?, inicio: Date, calendar: Calendar = .current) throws {
        guard let dataFim else { return }
        guard calendar.startOfDay(for: dataFim) >= calendar.startOfDay(for: inicio) else {
            throw CashUpDomainError.dataFimAnteriorAoInicio
        }
        let limite = calendar.date(byAdding: .year, value: limiteMaximoAnos, to: inicio) ?? inicio
        guard dataFim <= limite else { throw CashUpDomainError.dataFimMuitoDistante }
    }
}
```

### 1.4 `generateOccurrences` limitado ao intervalo consultado

```swift
let limiteDaSerie = repetitionData.endDate ?? queryInterval.end
let limiteDoLoop = min(limiteDaSerie, queryInterval.end)

while currentDateInLoop <= limiteDoLoop {
    ...
}
```

Remover o `break` condicional da linha 73 (fica redundante) e o `if let definiteEndDate ... break` da linha 67.

### 1.5 `AddTransactionViewModel`: edição centralizada, sem `?? Date()`

```swift
@MainActor
final class AddTransactionViewModel: ObservableObject {
    @Published var selectedTransactionType: Int = 0
    @Published var amount: Double = 0.0
    @Published var expenseDescription: String = ""
    @Published var selectedDate: Date = Date()
    @Published var repeatOption: RepeatOption = .nunca
    @Published var repeatEndDate: Date?
    @Published var selectedCategoria: CategoriaModel?
    @Published var selectedSubcategoria: SubcategoriaModel?
    @Published var errorMessage: String?

    private let transacaoEmEdicao: ExpenseModel?

    init(transacaoEmEdicao: ExpenseModel? = nil) {
        self.transacaoEmEdicao = transacaoEmEdicao
        guard let transacao = transacaoEmEdicao else { return }
        amount = transacao.amount
        selectedDate = transacao.date
        expenseDescription = transacao.expenseDescription
        selectedTransactionType = transacao.isIncome ? 1 : 0
        repeatOption = transacao.repetition?.repeatOption ?? .nunca
        repeatEndDate = transacao.repetition?.endDate
        selectedCategoria = transacao.categoria
        selectedSubcategoria = transacao.subcategoria
    }

    var isEditando: Bool { transacaoEmEdicao != nil }

    func salvar(usando expensesViewModel: ExpensesViewModel) async -> Bool {
        do {
            try validarCampos()
            if let transacao = transacaoEmEdicao {
                try aplicarEdicao(em: transacao, usando: expensesViewModel)
            } else {
                try expensesViewModel.addExpense(montarNovaTransacao())
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func aplicarEdicao(em transacao: ExpenseModel, usando expensesViewModel: ExpensesViewModel) throws {
        let repeticaoAtual = transacao.repetition ?? RepetitionData(repeatOption: .nunca, endDate: nil)
        transacao.repetition = repeticaoAtual.atualizando(opcao: repeatOption, dataFim: repeatEndDate)
        transacao.amount = amount
        transacao.date = selectedDate
        transacao.expenseDescription = expenseDescription
        transacao.categoria = selectedCategoria
        transacao.subcategoria = selectedSubcategoria
        transacao.isIncome = resolverIsIncome()
        try expensesViewModel.salvarEdicao()
    }
}
```

`validarCampos()` lança `valorInvalido`, `categoriaAusente`, `dataMuitoDistante` e chama `RepetitionData.validar`. Os campos só são escritos no modelo depois da validação, eliminando a mutação parcial. Remover `init(from:)`, `loadTransaction`, `criarTransacaoEChamarClosure`, `onTransactionCreated` e `resetFields` (a View descarta o VM ao fechar).

### 1.6 `ExpensesViewModel.addExpense` propaga erro

```swift
func addExpense(_ expense: ExpenseModel) throws {
    try validar(expense)
    modelContext.insert(expense)
    do {
        try modelContext.save()
    } catch {
        modelContext.rollback()
        throw CashUpDomainError.persistencia(error.localizedDescription)
    }
    loadDisplayableExpenses()
}

func salvarEdicao() throws {
    do { try modelContext.save() } catch {
        modelContext.rollback()
        throw CashUpDomainError.persistencia(error.localizedDescription)
    }
    loadDisplayableExpenses()
}
```

### 1.7 `ErrorAlertModifier` (componente reutilizável)

```swift
import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert("Erro", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    func errorAlert(_ message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }
}
```

### 1.8 `AddTransactionView` após a etapa

O botão "Salvar/Adicionar" vira:

```swift
Button(addTransactionVM.isEditando ? "Salvar" : "Adicionar") {
    Task {
        if await addTransactionVM.salvar(usando: expensesViewModel) {
            showSuccessAlert = true
        }
    }
}
.disabled(!addTransactionVM.podeSalvar)
```

A View perde `@State selectedCategoryModel/selectedSubcategoryModel`, `showErrorAlert`, `errorMessage`, `onEditComplete` e o `.onAppear` com closure. Adota `.errorAlert($addTransactionVM.errorMessage)`.

### 1.9 Testes

| Arquivo | Caso | Assert |
|---|---|---|
| `RepetitionDataEditingTests` | `atualizando` preserva `excludedDates` | `excludedDates` igual ao original |
| | `atualizando(opcao: .nunca)` | retorna `nil` |
| | `validar` com fim anterior ao início | lança `.dataFimAnteriorAoInicio` |
| | `validar` com fim em 11 anos | lança `.dataFimMuitoDistante` |
| `GenerateOccurrencesBoundsTests` | diária com `endDate` em 100 anos, consulta de 1 mês | `count <= 31` e `measure` abaixo de 5 ms |
| | série sem fim com data futura | ocorrências só a partir da data |
| | `endDate` igual ao último dia do mês | última ocorrência incluída |
| `AddTransactionErrorPropagationTests` | editar série sem `endDate` | `repetition?.endDate == nil` após salvar |
| | editar série com ocorrência excluída | `excludedDates.count == 1` após salvar |
| | `addExpense` com data em 101 anos | `salvar` retorna `false` e `errorMessage != nil` |
| | `addExpense` válido | `transacoesExibidas.count == 1` |

### 1.10 Limpeza ao final da Etapa 1

- Apagar `struct RepeatSettingsSheetView` de `PlanningPlanejarView.swift` (nunca usado).
- Apagar de `AddTransactionViewModel`: `init(from:)`, `loadTransaction`, `criarTransacaoEChamarClosure`, `onTransactionCreated`, `resetFields`, `currencyFormatter`.
- Apagar de `ExpensesViewModel.addExpense` os parâmetros `categoriaModel` e `subcategoriaModel` (nunca usados) e atualizar `CashUpUnitTests.swift`, `ExpenseModelTests.swift`, `ExpenseIntegrationTests.swift`, `CategoriesUnitTests.swift` para a nova assinatura.
- Apagar `onEditComplete` de `ExpensesListView.swift` e `SubcategoryDetailView.swift` (a recarga agora acontece em `salvarEdicao`).

---

## Etapa 2 — Médios: regras de negócio

**Objetivo**: tipo de transação e categoria sempre coerentes; cálculos respeitam o mês pedido; exclusão de recorrência igual em todas as telas.

### 2.1 Arquivos

```
CashUp/
├── Views/Transação/
│   ├── AddTransactionViewModel.swift                 ← MODIFICAR (regra Renda + limpeza ao trocar tipo)
│   └── Componentes/RepeatOptionPicker.swift          ← MODIFICAR (texto)
├── Views/Despesas/
│   ├── ExpensesViewModel.swift                       ← MODIFICAR (transactions(in:))
│   ├── Componentes/RecurringScopeDialogModifier.swift ← CRIAR
│   ├── ExpensesListView.swift                        ← MODIFICAR (usa o modifier)
│   └── SubcategoryDetailView.swift                   ← MODIFICAR (usa o modifier)
└── Sources/Extensions/Components/
    └── ExpenseCalculationProtocol.swift              ← MODIFICAR (contrato honra o mês)
CashUpUnitTests/Transacao/TransactionTypeRulesTests.swift          ← CRIAR
CashUpUnitTests/Despesas/ExpenseCalculationByMonthTests.swift       ← CRIAR
```

### 2.2 Regra Renda e sincronização tipo ↔ categoria

```swift
@Published var selectedTransactionType: Int = 0 {
    didSet {
        guard oldValue != selectedTransactionType else { return }
        selectedCategoria = nil
        selectedSubcategoria = nil
    }
}

func resolverIsIncome() -> Bool {
    selectedCategoria?.id == SeedIDs.idRenda || selectedTransactionType == 1
}

var podeSalvar: Bool {
    amount > 0 && selectedCategoria != nil && selectedSubcategoria != nil
}
```

Ao selecionar uma subcategoria de Renda com tipo "Despesa", o VM força `selectedTransactionType = 1` (sem disparar a limpeza, usando um flag interno `isAjustandoTipo`).

### 2.3 `ExpensesViewModel` com um único caminho de leitura

```swift
func transactions(in month: Date) -> [DisplayableExpense] {
    guard let interval = Calendar.current.dateInterval(of: .month, for: month.startOfMonth()) else { return [] }
    return fetchAll().flatMap { $0.generateOccurrences(forDateInterval: interval) }
}

func expenses(in month: Date) -> [DisplayableExpense] { transactions(in: month).filter { !$0.isIncome } }
func incomes(in month: Date) -> [DisplayableExpense] { transactions(in: month).filter { $0.isIncome } }

func totaisPorSubcategoria(in month: Date) -> [UUID: Double] {
    expenses(in: month).reduce(into: [:]) { acc, item in
        guard let id = item.subcategoria?.id else { return }
        acc[id, default: 0] += item.amount
    }
}

func calcularTotalGastoParaSubcategoria(_ sub: SubcategoriaPlanejadaModel, paraMes mes: Date) -> Double {
    guard let id = sub.subcategoriaOriginal?.id else { return 0 }
    return totaisPorSubcategoria(in: mes)[id] ?? 0
}
```

`generateOccurrences` já trata o caso sem repetição, então `loadDisplayableExpenses`, `allTransactionsForCurrentMonth` e `fetchTransactions(forSpecificDate:)` passam a delegar para `transactions(in:)`.

### 2.4 `RecurringScopeDialogModifier` (um dialog, três botões, usado por todas as listas)

```swift
import SwiftUI

struct RecurringScopeDialogModifier: ViewModifier {
    @Binding var item: DisplayableExpense?
    let titulo: String
    let onScope: (DisplayableExpense, RecurringExpenseDeletionScope) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(titulo, isPresented: Binding(
            get: { item != nil },
            set: { if !$0 { item = nil } }
        ), presenting: item) { expense in
            Button("Somente esta ocorrência") { onScope(expense, .thisOccurrenceOnly) }
            Button("Esta e todas as futuras") { onScope(expense, .thisAndAllFutureOccurrences) }
            Button("Toda a série", role: .destructive) { onScope(expense, .entireSeries) }
            Button("Cancelar", role: .cancel) {}
        } message: { expense in
            Text(RecurringScopeMessage.texto(para: expense))
        }
    }
}

extension View {
    func recurringScopeDialog(
        item: Binding<DisplayableExpense?>,
        titulo: String,
        onScope: @escaping (DisplayableExpense, RecurringExpenseDeletionScope) -> Void
    ) -> some View {
        modifier(RecurringScopeDialogModifier(item: item, titulo: titulo, onScope: onScope))
    }
}
```

`ExpensesListView` e `SubcategoryDetailView` aplicam o modifier uma única vez no `List`. O `confirmationDialog` por linha de `ExpenseRowView` é removido.

### 2.5 Texto do `RepeatOptionPicker`

Trocar "ela continuará por 1 ano como padrão" por "sem data, a repetição continua indefinidamente". O limite real (10 anos) é validado pelo VM na Etapa 1.

### 2.6 Testes

| Arquivo | Caso | Assert |
|---|---|---|
| `TransactionTypeRulesTests` | trocar tipo limpa categoria | `selectedCategoria == nil` |
| | subcategoria de Renda com tipo Despesa | `resolverIsIncome() == true` e tipo vira 1 |
| | editar Renda e trocar para Despesa | `isIncome` continua `true` |
| `ExpenseCalculationByMonthTests` | `calcularTotalGastoParaCategoria(paraMes: março)` com `currentMonth = abril` | total de março |
| | `totaisPorSubcategoria` com 2 subcategorias | dicionário com 2 chaves e somas corretas |

### 2.7 Limpeza ao final da Etapa 2

- Apagar `struct ExpenseRowView` de `SubcategoryDetailView.swift` (substituída por `DisplayableExpenseRow` + swipe + modifier).
- Apagar de `ExpensesViewModel`: `allTransactionsForCurrentMonth`, `expensesOnlyForCurrentMonth`, `incomesOnlyForCurrentMonth`, `totalIncomeForCurrentMonth`, `totalExpenseForCurrentMonth` (substituídos por `expenses(in:)`/`incomes(in:)`), ajustando `HomeViewModel`, `ExpensesView` e os testes `ExpenseModelTests`, `RepetitionIntegrationTestes`, `UnitTestLAGastoParaCategoria`.
- Apagar `@State showRecurrenceDeleteOptions` das duas listas (o modifier deriva o estado de `item`).

---

## Etapa 3 — Testes quebrados e vazios

### 3.1 Arquivos

```
CashUpUnitTests/
├── RepetitionDataTestes.swift        ← MODIFICAR (datas fixas)
├── CashUpUnitTests.swift             ← MODIFICAR (apagar testExample/testPerformanceExample)
├── testeLAUnit.swift                 ← RENOMEAR → Despesas/DisplayableExpenseTests.swift
├── UnitTestLAGastoParaCategoria.swift← RENOMEAR → Despesas/ExpenseCalculationTests.swift
├── RepetitionDataTestes.swift        ← RENOMEAR → Transacao/RepetitionDataTests.swift
└── RepetitionIntegrationTestes.swift ← RENOMEAR → Transacao/RepetitionIntegrationTests.swift
CashUpUITests/
├── testesUILA.swift                  ← RENOMEAR → PlanningUITests.swift
├── RepetitionUITestes.swift          ← RENOMEAR → RepetitionUITests.swift
└── ExpenseModelUITest.swift          ← RENOMEAR → ExpensesUITests.swift
```

### 3.2 Regras

- Nenhum teste usa `Date()` para montar dados que serão comparados a um mês fixo. Usar `Date.make(year:month:day:)` sempre.
- `test_ExpenseOnlyInMonth` passa a criar a despesa em `2026-03-15`.
- Todo arquivo de teste segue `<Nome>Tests.swift` e fica numa subpasta por domínio (`Transacao/`, `Despesas/`, `Categoria/`, `Planejamento/`).
- Testes de UI usam `waitForExistence(timeout:)`; nunca `sleep`.

### 3.3 Limpeza ao final da Etapa 3

- Apagar `testExample`, `testPerformanceExample` (vazios) e os `testLaunchPerformance` comentados.
- Apagar `CashUpUITestsLaunchTests.swift` se `testLaunch` só tirar screenshot sem assert; caso contrário, manter com assert do `addTransactionButtonHome`.

---

## Etapa 4 — Limpeza técnica e performance

### 4.1 Arquivos

```
CashUp/
├── Models/SeedData.swift                               ← MODIFICAR (bloco único)
├── CashUpApp.swift                                     ← MODIFICAR (fallback em memória + RootView)
├── Sources/Extensions/
│   ├── Formatters/BRLCurrencyFormatter.swift           ← CRIAR
│   ├── Formatters/SectionDateFormatter.swift           ← CRIAR
│   └── Logging/CashUpLogger.swift                      ← CRIAR
├── Views/Home/
│   ├── HomeView.swift                                  ← MODIFICAR (chart usa VM existente, sem _printChanges)
│   ├── HomeViewModel.swift                             ← MODIFICAR (um fetch por update)
│   └── Componentes/
│       ├── MiniChartCard.swift                         ← CRIAR (extraído de HomeView)
│       ├── PlanningCard.swift                          ← CRIAR
│       └── ExpensesSummaryCard.swift                   ← CRIAR
├── Views/Planejamento/PlanningRestanteView.swift       ← MODIFICAR (totais calculados uma vez)
└── Views/Despesas/
    ├── utilsExpenses.swift                             ← APAGAR
    └── ExpensesListView.swift                          ← MODIFICAR (sem funções globais)
CashUpUnitTests/Categoria/SeedDataTests.swift            ← CRIAR
CashUpUnitTests/Home/HomeViewModelTests.swift            ← CRIAR
```

### 4.2 Formatters únicos

```swift
import Foundation

enum BRLCurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    static func string(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}
```

`SectionDateFormatter.titulo(para:)` devolve "Hoje", "Ontem" ou "Quarta, 08/10", único formato para listas.

### 4.3 Logger

```swift
import os

enum CashUpLogger {
    static let persistence = Logger(subsystem: "com.cashup.app", category: "persistence")
    static let ui = Logger(subsystem: "com.cashup.app", category: "ui")
}
```

Todos os `print` viram `CashUpLogger.x.error("...")` ou são removidos. Nunca logar `amount` ou `expenseDescription`.

### 4.4 Refresh sem hacks

- `AddTransactionView` recebe o mesmo `ExpensesViewModel` via `@EnvironmentObject`; `salvarEdicao()` já chama `loadDisplayableExpenses()`. Remover `.id(UUID())` e `DispatchQueue.main.asyncAfter`.
- `showDuplicateAlert` em `PlanningPlanejarView` passa a usar `.task(id:)` com `Task.sleep` em vez de `asyncAfter`.
- `HomeView.miniChartCard` usa `homeViewModel.expensesViewModel`; `InteractiveDailyExpensesChart` deixa de instanciar VM.
- `DailyExpenseItem.id` vira `date` (`var id: Date { date }`).
- `HomeViewModel.updateCardData` chama `transactions(in:)` uma vez e deriva despesas, receitas e totais da mesma lista.
- `PlanningRestanteView` recebe `totaisPorSubcategoria` calculado uma vez no `body` e passa o dicionário aos componentes.

### 4.5 `CashUpApp` sem `ModelContainer()`

```swift
static func makeContainer(inMemory: Bool) -> ModelContainer {
    let schema = Schema([CategoriaModel.self, SubcategoriaModel.self, ExpenseModel.self,
                         CategoriaPlanejadaModel.self, SubcategoriaPlanejadaModel.self])
    do {
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
    } catch {
        CashUpLogger.persistence.critical("Container persistente falhou: \(error.localizedDescription)")
        return (try? ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
            ?? { fatalError("Sem container em memória: \(error)") }()
    }
}
```

### 4.6 Modelos

- `ExpenseModel.id` recebe `@Attribute(.unique)`.
- `ExpenseModel.categoria` e `.subcategoria` recebem `@Relationship(deleteRule: .nullify)` explícito (a Etapa 8 bloqueia a exclusão de categoria em uso antes de chegar aqui).
- Cabeçalhos `Created by [Seu Nome] on [Data]` removidos de `ExpensesView.swift` e `ExpensesViewModel.swift`.

### 4.7 Testes

| Arquivo | Caso | Assert |
|---|---|---|
| `SeedDataTests` | executar seed 2 vezes | 7 categorias e 71 subcategorias |
| `HomeViewModelTests` | 50 despesas no mês | `totalSpentMonth` correto, `categoriasResumo` ordenado desc |
| | `measure { updateCardData() }` | linha de base registrada |

### 4.8 Limpeza ao final da Etapa 4

- Apagar `utilsExpenses.swift`, `formatCurrency` global e `formatSectionDate` global de `ExpensesListView.swift`, `HomeViewModel.formatCurrency`, `PlanningRestanteView.formatCurrency`, `CurrencyAmountField.formattedAmount` (usa `BRLCurrencyFormatter`).
- Apagar o segundo bloco `do { ... }` de `popularDadosIniciaisSeNecessario` e os `print` comentados.
- Apagar `Self._printChanges()` de `HomeView` e `PlanningView`.
- Apagar `ExpensesViewModel.configure(with:)` (sem chamadas).

---

## Etapa 5 — Camada de Repositório

**Objetivo**: ViewModels sem `ModelContext`; testes com mocks puros.

### 5.1 Arquivos

```
CashUp/
├── Protocols/
│   ├── Despesas/ExpenseRepositoryProtocol.swift           ← CRIAR
│   ├── Categoria/CategoriaRepositoryProtocol.swift        ← CRIAR
│   └── Planejamento/PlanningRepositoryProtocol.swift      ← CRIAR
├── Repositories/
│   ├── Despesas/SwiftDataExpenseRepository.swift          ← CRIAR
│   ├── Categoria/SwiftDataCategoriaRepository.swift       ← CRIAR
│   └── Planejamento/SwiftDataPlanningRepository.swift     ← CRIAR
├── Views/Despesas/ExpensesViewModel.swift                 ← MODIFICAR (init(repository:))
├── Views/Categoria/CategoriesViewModel.swift              ← MODIFICAR
├── Views/Planejamento/PlanningViewModel.swift             ← MODIFICAR
├── Views/Home/HomeViewModel.swift                         ← MODIFICAR
└── Views/Home/HomeView.swift                              ← MODIFICAR (composition root)
CashUpUnitTests/Mocks/
├── InMemoryExpenseRepository.swift                        ← CRIAR
├── InMemoryCategoriaRepository.swift                      ← CRIAR
└── InMemoryPlanningRepository.swift                       ← CRIAR
```

### 5.2 Protocolos

```swift
protocol ExpenseRepositoryProtocol {
    func fetchAll() throws -> [ExpenseModel]
    func fetch(id: UUID) throws -> ExpenseModel?
    func insert(_ expense: ExpenseModel) throws
    func delete(_ expense: ExpenseModel) throws
    func save() throws
}

protocol CategoriaRepositoryProtocol {
    func fetchCategorias(filtro: TransactionTypeFilter?) throws -> [CategoriaModel]
    func fetchSubcategoriasMaisUsadas(filtro: TransactionTypeFilter, limite: Int) throws -> [SubcategoriaModel]
    func fetchCategoria(id: UUID) throws -> CategoriaModel?
    func fetchSubcategoria(id: UUID) throws -> SubcategoriaModel?
    func contarTransacoes(categoriaID: UUID) throws -> Int
    func insert(_ categoria: CategoriaModel) throws
    func delete(_ categoria: CategoriaModel) throws
    func delete(_ subcategoria: SubcategoriaModel) throws
    func save() throws
}

protocol PlanningRepositoryProtocol {
    func fetchCategoriasPlanejadas(mes: Date) throws -> [CategoriaPlanejadaModel]
    func fetchCategoriaPlanejada(mes: Date, categoriaID: UUID) throws -> CategoriaPlanejadaModel?
    func fetchSubcategoriaPlanejada(id: UUID) throws -> SubcategoriaPlanejadaModel?
    func insert(_ categoriaPlanejada: CategoriaPlanejadaModel) throws
    func delete(_ categoriaPlanejada: CategoriaPlanejadaModel) throws
    func delete(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel) throws
    func save() throws
}
```

Síncronos porque `ModelContext` do `mainContext` é `@MainActor`; os ViewModels já são `@MainActor`.

### 5.3 Composition root em `HomeView.init`

```swift
init(modelContext: ModelContext) {
    let expenseRepository = SwiftDataExpenseRepository(context: modelContext)
    let planningRepository = SwiftDataPlanningRepository(context: modelContext)
    let categoriaRepository = SwiftDataCategoriaRepository(context: modelContext)
    ...
}
```

`CategorySelectionSheet` e `PlanningPlanejarView` recebem `CategoriaRepositoryProtocol` por parâmetro em vez de `modelContext`.

### 5.4 Testes

- Todos os testes de ViewModel passam a usar os `InMemory*Repository` (arrays em memória, sem SwiftData).
- Testes de repositório concreto (`SwiftDataExpenseRepositoryTests` etc.) continuam com `isStoredInMemoryOnly: true`.

### 5.5 Limpeza ao final da Etapa 5

- Apagar `var modelContext` de todos os ViewModels.
- Apagar `findCategoriaModel`/`findSubcategoriaModel` duplicados em `ExpensesViewModel` (ficam só no repositório).
- Apagar `CategoriesViewModel.getModelContextForEditing` e `getTransactionTypeFilter` (expor `let transactionType`).

---

## Etapa 6 — Biometria (Face ID / Touch ID)

### 6.1 Arquivos

```
CashUp/
├── Services/Auth/
│   ├── BiometricAuthServiceProtocol.swift         ← CRIAR
│   └── BiometricAuthService.swift                 ← CRIAR (LAContext)
├── Services/Settings/
│   ├── AppSettingsProtocol.swift                  ← CRIAR
│   └── UserDefaultsAppSettings.swift              ← CRIAR
├── Views/Boas Vindas/
│   ├── RootView.swift                             ← CRIAR (Welcome → Onboarding → Lock → Home)
│   └── Biometria/
│       ├── AuthViewModel.swift                    ← PREENCHER
│       ├── BiometricLockView.swift                ← CRIAR
│       └── Componentes/
│           ├── BiometricPromptCard.swift          ← CRIAR
│           └── BiometricUnavailableCard.swift     ← CRIAR
├── Views/Configurações/
│   ├── SettingsView.swift                         ← CRIAR (toggle de bloqueio)
│   └── SettingsViewModel.swift                    ← CRIAR
└── CashUpApp.swift                                ← MODIFICAR (scenePhase)
CashUp.xcodeproj/project.pbxproj                   ← MODIFICAR: INFOPLIST_KEY_NSFaceIDUsageDescription nos dois buildSettings do target CashUp
CashUpUnitTests/Biometria/AuthViewModelTests.swift ← CRIAR
CashUpUnitTests/Mocks/MockBiometricAuthService.swift ← CRIAR
```

### 6.2 Serviço

```swift
import LocalAuthentication

enum BiometricKind { case none, touchID, faceID, opticID }

protocol BiometricAuthServiceProtocol {
    var kind: BiometricKind { get }
    var isAvailable: Bool { get }
    func authenticate(reason: String) async throws -> Bool
}

final class BiometricAuthService: BiometricAuthServiceProtocol {
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}
```

`.deviceOwnerAuthentication` permite fallback para o código do aparelho.

### 6.3 `AuthViewModel`

```swift
@MainActor
final class AuthViewModel: ObservableObject {
    enum Estado: Equatable { case bloqueado, autenticando, liberado, falhou(String), indisponivel }

    @Published private(set) var estado: Estado = .bloqueado
    private let service: BiometricAuthServiceProtocol
    private let settings: AppSettingsProtocol

    init(service: BiometricAuthServiceProtocol, settings: AppSettingsProtocol) { ... }

    var precisaBloquear: Bool { settings.isBiometricLockEnabled && service.isAvailable }

    func autenticar() async {
        estado = .autenticando
        do {
            estado = try await service.authenticate(reason: "Desbloqueie o CashUp") ? .liberado : .falhou("Autenticação cancelada.")
        } catch {
            estado = .falhou(error.localizedDescription)
        }
    }

    func bloquear() { estado = .bloqueado }
}
```

### 6.4 Regras

- Flag `--uitesting` desativa o bloqueio.
- `scenePhase == .background` chama `bloquear()`; ao voltar a `.active` a `BiometricLockView` chama `autenticar()` automaticamente.
- Se a biometria for removida do aparelho (`isAvailable == false`), o bloqueio é ignorado e `SettingsView` mostra `BiometricUnavailableCard`.

### 6.5 Testes

| Caso | Assert |
|---|---|
| mock devolve `true` | `estado == .liberado` |
| mock lança `LAError.userCancel` | `estado == .falhou(...)` |
| `isAvailable == false` | `precisaBloquear == false` |
| bloqueio desativado nas settings | `precisaBloquear == false` |

### 6.6 Limpeza ao final da Etapa 6

- Apagar `BiometricView.swift` (placeholder `Text("Logo")`), substituído por `BiometricLockView.swift`.
- Apagar o `ZStack` com `if isShowingWelcomeScreen` de `CashUpApp.swift`; a decisão de fluxo passa a viver em `RootView`.

---

## Etapa 7 — Onboarding

### 7.1 Arquivos

```
CashUp/Views/Boas Vindas/
├── WelcomeView.swift                         ← MODIFICAR (Timer → .task)
└── Onboarding/
    ├── OnboardingPage.swift                  ← CRIAR (struct)
    ├── OnboardingViewModel.swift             ← PREENCHER
    ├── OnboardingView.swift                  ← PREENCHER (TabView paginada)
    └── Componentes/
        ├── OnboardingPageView.swift          ← CRIAR
        ├── OnboardingPageIndicator.swift     ← CRIAR
        └── OnboardingActionsBar.swift        ← CRIAR (Pular / Próximo / Começar)
CashUpUnitTests/Onboarding/OnboardingViewModelTests.swift ← CRIAR
CashUpUITests/OnboardingUITests.swift                     ← CRIAR
```

### 7.2 Conteúdo das páginas

| # | Título | Mensagem | Ícone |
|---|---|---|---|
| 1 | Registre em segundos | Valor, categoria e pronto. Sem conta, sem internet. | `bolt.fill` |
| 2 | Planeje o mês | Defina tetos por subcategoria e acompanhe o restante. | `chart.pie.fill` |
| 3 | Seus dados são seus | Tudo fica no aparelho. Ative o Face ID se quiser. | `faceid` |

A página 3 mostra o toggle de biometria (reusa `SettingsViewModel`).

### 7.3 `OnboardingViewModel`

```swift
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var paginaAtual: Int = 0
    let paginas: [OnboardingPage]
    private let settings: AppSettingsProtocol

    var isUltimaPagina: Bool { paginaAtual == paginas.count - 1 }

    func avancar() { paginaAtual = min(paginaAtual + 1, paginas.count - 1) }
    func concluir() { settings.hasCompletedOnboarding = true }
}
```

`RootView` exibe o onboarding quando `!settings.hasCompletedOnboarding` e `--uitesting` não contém `--skip-onboarding`.

### 7.4 Limpeza ao final da Etapa 7

- `WelcomeView` troca `Timer.scheduledTimer` por `.task { try? await Task.sleep(for: .seconds(2.5)); ... }` (cancelável).
- Garantir que não restam arquivos de 0 bytes em `Boas Vindas/`.

---

## Etapa 8 — CRUD de categorias personalizadas

### 8.1 Arquivos

```
CashUp/Views/Categoria/
├── CategoriesViewEdit.swift                  ← APAGAR
├── CategoriesEditView.swift                  ← CRIAR (lista + swipe + menu)
├── CategoriaEditorViewModel.swift            ← CRIAR
├── CategoriaFormView.swift                   ← CRIAR (sheet criar/editar categoria)
├── SubcategoriaFormView.swift                ← CRIAR (sheet criar/editar subcategoria)
└── Componentes/
    ├── CategoriaSectionView.swift            ← MOVER de CategoriesViewEdit.swift
    ├── ColorSwatchGrid.swift                 ← CRIAR
    ├── SymbolPickerGrid.swift                ← CRIAR
    └── DeleteCategoriaConfirmation.swift     ← CRIAR (modifier)
CashUpUnitTests/Categoria/CategoriaEditorViewModelTests.swift ← CRIAR
CashUpUITests/CategoriesEditUITests.swift                     ← CRIAR
```

### 8.2 Regras de negócio

| Regra | Comportamento |
|---|---|
| Categoria `Renda` (`SeedIDs.idRenda`) | não pode ser renomeada, apagada nem perder a última subcategoria |
| Categorias seed | podem ser renomeadas e receber subcategorias; só podem ser apagadas sem transações |
| Apagar categoria com transações | lança `CashUpDomainError.categoriaEmUso(quantidadeTransacoes:)` |
| Apagar subcategoria com transações | transações migram para a subcategoria "Diversos" da mesma categoria, ou bloqueia se não existir |
| Nome | único por categoria, 2 a 24 caracteres, sem espaços nas pontas |
| Cor | escolhida entre 12 swatches fixos (`CategoriaPalette`) |
| Ícone | escolhido de uma lista curada de ~40 SF Symbols (`CategoriaSymbols`) |

### 8.3 `CategoriaEditorViewModel`

```swift
@MainActor
final class CategoriaEditorViewModel: ObservableObject {
    @Published var categorias: [CategoriaModel] = []
    @Published var errorMessage: String?
    private let repository: CategoriaRepositoryProtocol

    func carregar()
    func criarCategoria(nome: String, cor: Color, icone: String) throws
    func renomearCategoria(_ categoria: CategoriaModel, nome: String) throws
    func apagarCategoria(_ categoria: CategoriaModel) throws
    func criarSubcategoria(em categoria: CategoriaModel, nome: String, icone: String) throws
    func apagarSubcategoria(_ subcategoria: SubcategoriaModel) throws
}
```

### 8.4 Testes

| Caso | Assert |
|---|---|
| criar categoria válida | aparece em `categorias`, cor convertida em RGB |
| nome duplicado | lança `.nomeDuplicado` |
| apagar categoria com 2 transações | lança `.categoriaEmUso(2)` |
| apagar Renda | lança `.categoriaProtegida` |
| apagar subcategoria com transações | transações apontam para "Diversos" |

### 8.5 Limpeza ao final da Etapa 8

- Apagar `CategoriesViewEdit.swift` por completo (todo o código comentado some com ele).
- Apagar `CategoriaSectionView` de dentro do arquivo antigo (vive em `Componentes/`).

---

## Etapa 9 — Edição de ocorrência única de recorrência

### 9.1 Estratégia

Editar uma ocorrência virtual nunca altera o `ExpenseModel` original fora do escopo escolhido:

| Escopo | Operação |
|---|---|
| Somente esta | adiciona a data em `excludedDates` do original e insere um `ExpenseModel` novo sem repetição com os valores editados |
| Esta e futuras | `endDate` do original = dia anterior; insere nova série começando na ocorrência com os valores editados e a mesma `repeatOption` |
| Toda a série | fluxo atual (edita o original) |

### 9.2 Arquivos

```
CashUp/
├── Models/RecurringScope.swift                           ← CRIAR (substitui RecurringExpenseDeletionScope)
├── Views/Despesas/
│   ├── ExpensesViewModel.swift                            ← MODIFICAR (editRecurring)
│   └── Componentes/RecurringScopeDialogModifier.swift     ← MODIFICAR (genérico: títulos por ação)
└── Views/Transação/
    ├── AddTransactionViewModel.swift                      ← MODIFICAR (recebe escopo)
    └── Componentes/RecurringEditScopeBanner.swift         ← CRIAR (informa o escopo no topo do form)
CashUpUnitTests/Transacao/RecurringEditTests.swift         ← CRIAR
```

### 9.3 API

```swift
enum RecurringScope { case thisOccurrenceOnly, thisAndAllFutureOccurrences, entireSeries }

struct ExpenseEdit {
    var amount: Double
    var date: Date
    var description: String
    var isIncome: Bool
    var categoria: CategoriaModel?
    var subcategoria: SubcategoriaModel?
    var repetition: RepetitionData?
}

func editRecurring(_ occurrence: DisplayableExpense, scope: RecurringScope, edit: ExpenseEdit) throws
```

### 9.4 Testes

| Caso | Assert |
|---|---|
| "somente esta" em série mensal | original com 1 `excludedDate`; nova transação isolada; total do mês inalterado se valor igual |
| "esta e futuras" | original `endDate` = dia anterior; nova série começa na ocorrência; mês seguinte usa valores novos |
| "toda a série" | original alterado; sem novas transações |
| "esta e futuras" na primeira ocorrência | original apagado; só a nova série existe |

### 9.5 Limpeza ao final da Etapa 9

- Apagar `RecurringExpenseDeletionScope` (substituído por `RecurringScope`), atualizando `removeExpense` e testes.

---

## Etapa 10 — Dicas dinâmicas

### 10.1 Arquivos

```
CashUp/
├── Resources/tips.json                               ← CRIAR
├── Protocols/Dicas/TipsRepositoryProtocol.swift      ← CRIAR
├── Repositories/Dicas/BundledTipsRepository.swift    ← CRIAR (decodifica tips.json)
└── Views/Dicas/
    ├── Tip.swift                                     ← PREENCHER (struct Codable, Identifiable)
    ├── TipsViewModel.swift                           ← PREENCHER
    ├── TipsView.swift                                ← MODIFICAR (só composição)
    └── Componentes/
        ├── FiftyThirtyTwentyCard.swift               ← CRIAR (extraído de TipsView)
        ├── TipCardView.swift                         ← CRIAR
        └── TipCategoryChips.swift                    ← CRIAR (filtro)
CashUpUnitTests/Dicas/TipsViewModelTests.swift        ← CRIAR
```

### 10.2 Modelo e VM

```swift
struct Tip: Codable, Identifiable, Equatable {
    enum Categoria: String, Codable, CaseIterable { case orcamento, economia, habitos, renda }
    let id: String
    let titulo: String
    let corpo: String
    let icone: String
    let categoria: Categoria
}

@MainActor
final class TipsViewModel: ObservableObject {
    @Published var categoriaSelecionada: Tip.Categoria?
    @Published private(set) var dicas: [Tip] = []
    @Published var errorMessage: String?

    var dicasFiltradas: [Tip] { ... }
    func carregar() async
    func dicaDoDia(referencia: Date) -> Tip?
}
```

`dicaDoDia` usa o dia do ano como índice determinístico; `HomeView` mostra um `TipCardView` compacto abaixo do gráfico.

### 10.3 Testes

| Caso | Assert |
|---|---|
| repositório mock com 5 dicas | `dicas.count == 5` |
| filtro `.economia` | só dicas da categoria |
| `dicaDoDia` para a mesma data | mesma dica em duas chamadas |
| JSON inválido | `errorMessage != nil`, `dicas` vazio |

### 10.4 Limpeza ao final da Etapa 10

- Mover o conteúdo estático hoje em `TipsView.swift` para `tips.json`; `TipsView` fica com menos de 60 linhas.

---

## Mapeamento consolidado de erros e casos de borda

| Cenário | Condição | Ação | Erro |
|---|---|---|---|
| Edição de série sem fim | `repetition.endDate == nil` | permanece `nil` | — |
| Edição de série com exclusões | `excludedDates` não vazio | preservado | — |
| Data fim antes do início | `endDate < date` | bloqueia | `.dataFimAnteriorAoInicio` |
| Data fim > 10 anos | | bloqueia | `.dataFimMuitoDistante` |
| Data > 100 anos | | bloqueia | `.dataMuitoDistante` |
| Falha de `save()` | SwiftData lança | `rollback()` + alerta | `.persistencia` |
| Trocar tipo após escolher categoria | | limpa seleção | — |
| Subcategoria de Renda com tipo Despesa | | força Receita | — |
| Apagar categoria com transações | `contarTransacoes > 0` | bloqueia | `.categoriaEmUso` |
| Biometria indisponível | `isAvailable == false` | pula bloqueio | — |
| `--uitesting` | | sem Welcome, Onboarding e Lock | — |

---

## Ordem de execução (Dependency-Ordered)

```
Etapa 1  ─ CashUpDomainError, RepetitionData.atualizando, loop limitado, ErrorAlertModifier,
           AddTransactionViewModel.salvar, ExpensesViewModel.addExpense throws
           └── Limpeza 1.10 → testes verdes
Etapa 2  ─ regra Renda, transactions(in:), RecurringScopeDialogModifier, texto do picker
           └── Limpeza 2.7 → testes verdes
Etapa 3  ─ datas fixas nos testes, renomeações, remoção de placeholders
           └── Limpeza 3.3 → testes verdes
Etapa 4  ─ formatters, logger, seed único, cards da Home em componentes, refresh sem hacks
           └── Limpeza 4.8 → testes verdes
Etapa 5  ─ protocolos, repositórios SwiftData, mocks em memória, composition root
           └── Limpeza 5.5 → testes verdes
Etapa 6  ─ BiometricAuthService, AuthViewModel, BiometricLockView, RootView, SettingsView
           └── Limpeza 6.6 → testes verdes
Etapa 7  ─ OnboardingViewModel, OnboardingView + componentes
           └── Limpeza 7.4 → testes verdes
Etapa 8  ─ CategoriaEditorViewModel, CategoriesEditView, forms e grids
           └── Limpeza 8.5 → testes verdes
Etapa 9  ─ RecurringScope, editRecurring, banner de escopo
           └── Limpeza 9.5 → testes verdes
Etapa 10 ─ tips.json, TipsViewModel, TipCardView, FiftyThirtyTwentyCard
           └── Limpeza 10.4 → testes verdes
```

---

## Checklist de qualidade por etapa

- [ ] Nenhum arquivo `.swift` com comentário, código comentado ou cabeçalho `[Seu Nome]`.
- [ ] Nenhum `print` em produção; apenas `CashUpLogger`.
- [ ] Nenhum `DispatchQueue.main.asyncAfter` nem `.id(UUID())` para forçar refresh.
- [ ] ViewModel `@MainActor final class`, dependências por `init`, `errorMessage` publicado.
- [ ] Toda View nova com `body` curto, composta por componentes em `Componentes/`.
- [ ] Testes com `Date.make(year:month:day:)`, nunca `Date()` comparado a mês fixo.
- [ ] Arquivos substituídos apagados no mesmo passo em que o substituto entra.
- [ ] `docs/rules/gap_analysis_and_roadmap.md` atualizado marcando a lacuna como concluída.
- [ ] `xcodebuild test` verde antes de iniciar a próxima etapa.
