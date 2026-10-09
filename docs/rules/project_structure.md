# 📁 Estrutura de Arquivos e Padrões de Código — CashUp

**Escopo**: Mapeamento físico de pastas, responsabilidades de arquivos, convenções de nomenclatura e Clean Code.  
**Referência**: Padrão de organização limpa e modular do `c18-api` adaptado para ecossistema Apple/Swift.  

---

## 1. Árvore Estrutural do Repositório

```
CashUp/
├── CashUp/                             ← Código-fonte principal da aplicação iOS
│   ├── CashUpApp.swift                 ← Ponto de entrada (@main) e inicialização do SwiftData
│   ├── Assets.xcassets/                ← Ícones do app, paleta AccentColor e recursos visuais
│   │
│   ├── Models/                         ← Modelos de dados e entidades SwiftData (@Model)
│   │   ├── CategoriaModel.swift        ← Categoria macro (cor, ícone, relacionamento 1:N)
│   │   ├── SubcategoriaModel.swift     ← Subcategoria com contador de uso (usageCount)
│   │   ├── ExpenseModel.swift          ← Transação principal e gerador de recorrências virtuais
│   │   ├── CategoriaPlanejadaModel.swift    ← Orçamento mensal alocado por categoria
│   │   ├── SubcategoriaPlanejadaModel.swift ← Orçamento alocado por subcategoria
│   │   ├── RepetitionData.swift        ← Estrutura de dados para repetição e datas excluídas
│   │   └── SeedData.swift              ← Categorias e subcategorias predefinidas com SeedIDs
│   │
│   ├── Views/                          ← Telas e componentes organizados por domínio funcional
│   │   ├── Home/                       ← Dashboard principal e resumo financeiro do mês
│   │   │   ├── HomeView.swift
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── InteractiveDailyExpensesChart.swift
│   │   │   └── DailyExpensesDetailView.swift
│   │   ├── Transação/                  ← Fluxo de criação e edição de receitas/despesas
│   │   │   ├── AddTransactionView.swift
│   │   │   ├── AddTransactionViewModel.swift
│   │   │   └── Componentes/            ← Campos de valor, data, categoria, recorrência
│   │   ├── Despesas/                   ← Listagem detalhada e histórico de transações
│   │   │   ├── ExpensesView.swift
│   │   │   ├── ExpensesViewModel.swift
│   │   │   ├── ExpensesListView.swift
│   │   │   └── SubcategoryDetailView.swift
│   │   ├── Planejamento/               ← Definição de orçamento e metas mensais
│   │   │   ├── PlanningView.swift
│   │   │   ├── PlanningViewModel.swift
│   │   │   ├── PlanningPlanejarView.swift
│   │   │   └── PlanningRestanteView.swift
│   │   ├── Categoria/                  ← Catálogo taxonômico e favoritos
│   │   │   ├── CategoriesView.swift
│   │   │   ├── CategoriesViewModel.swift
│   │   │   └── CategoriesViewEdit.swift
│   │   ├── Boas Vindas/                ← Onboarding e telas de entrada
│   │   │   ├── WelcomeView.swift       ← Splash de inicialização (2.5s)
│   │   │   ├── Onboarding/             ← Fluxo de apresentação inicial
│   │   │   └── Biometria/              ← Autenticação biométrica
│   │   └── Dicas/                      ← Educação financeira e regra 50/30/20
│   │       ├── TipsView.swift
│   │       ├── TipsViewModel.swift
│   │       └── Tip.swift
│   │
│   └── Sources/
│       └── Extensions/                 ← Extensões de sistema, helpers e componentes base
│           ├── DateExtension.swift     ← startOfMonth(), formatações e cálculos de calendário
│           ├── ViewExtensions.swift    ← Modificadores visuais reutilizáveis
│           └── Components/             ← MonthSelector, TransactionPicker, Protocolos
│
├── CashUpUnitTests/                    ← Suíte de Testes Unitários (XCTest) com banco in-memory
├── CashUpUITests/                      ← Suíte de Testes de Interface (XCUITest)
├── docs/                               ← Documentação técnica, regras e planos de implementação
│   ├── rules/
│   └── plans/
├── CashUp.xcodeproj                    ← Configuração e targets do projeto Xcode
├── Gemfile                             ← Gerenciamento de dependências Ruby (Fastlane/CocoaPods)
└── README.md                           ← Apresentação inicial do repositório
```

---

## 2. Convenções de Nomenclatura de Arquivos e Tipos

A nomenclatura de arquivos em Swift deve ser rigorosa e autoexplicativa:

| Tipo de Artefato | Padrão do Nome do Arquivo | Padrão do Nome do Tipo | Exemplo |
|---|---|---|---|
| **Modelo SwiftData** | `<Nome>Model.swift` | `<Nome>Model` | `ExpenseModel.swift` |
| **Tela / Componente View** | `<Nome>View.swift` | `<Nome>View` | `HomeView.swift` |
| **ViewModel** | `<Nome>ViewModel.swift` | `<Nome>ViewModel` | `PlanningViewModel.swift` |
| **Protocolo de Repositório** | `<Nome>RepositoryProtocol.swift` | `<Nome>RepositoryProtocol` | `ExpenseRepositoryProtocol.swift` |
| **Repositório Concreto** | `<Nome>Repository.swift` | `<Nome>Repository` | `ExpenseRepository.swift` |
| **Extensão** | `<TipoBase>+<Propósito>.swift` | `extension <TipoBase>` | `Date+MonthInterval.swift` |
| **Teste Unitário** | `<Nome>Tests.swift` | `<Nome>Tests: XCTestCase` | `ExpenseModelTests.swift` |
| **Teste de UI** | `<Nome>UITests.swift` | `<Nome>UITests: XCTestCase` | `CategoriesUITests.swift` |

---

## 3. Diretrizes de Clean Code (Padrão Rigoroso)

Inspirado nas diretrizes estritas do projeto `c18-api`:

### 3.1 Proibição de Comentários Redundantes
- **Regra**: Não escreva comentários no código explicando o óbvio (ex: `// salva o contexto`, `// se for nulo retorna`, `// MARK: - inicializador`).
- O código deve revelar sua intenção através de:
  - Nomes de variáveis e funções claros, declarativos e em inglês ou português consistente.
  - Funções de responsabilidade única (máximo 25-30 linhas por método).
  - Tipagem estrita de retorno e tratamento tipado de erros (`throws`).

### 3.2 Eliminação de Código Comentado (Dead Code)
- **Regra**: Código antigo, funções desativadas ou blocos comentados **não devem permanecer no repositório**.
- Se uma funcionalidade estiver em desenvolvimento, ela deve estar isolada em branch ou protegida por feature flag, e não comentada inline dentro de uma View (como verificado em `CategoriesViewEdit.swift`).

### 3.3 Uso Estruturado de Early Exit (`guard`)
- Prefira cláusulas `guard let` ou `guard condition else { return / throw }` no início dos métodos em vez de encadeamento profundo de `if / else`.
- Reduz a complexidade ciclomática e mantém a indentação do fluxo principal plana.

```swift
// Padrão Recomendado
func cadastrarTransacao(_ payload: TransactionPayload) throws {
    guard payload.amount > 0 else {
        throw CashUpError.invalidAmount
    }
    guard let categoria = payload.categoria else {
        throw CashUpError.missingCategory
    }
    
    // Fluxo principal limpo e legível
    let expense = ExpenseModel(...)
    try repository.insert(expense)
}
```

### 3.4 Desacoplamento e Injeção de Dependências
- ViewModels não devem instanciar singletons opacos de banco de dados diretamente; devem receber o `ModelContext` ou o `Repository` correspondente através do construtor (`init`).
