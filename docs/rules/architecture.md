# 🏛️ Arquitetura de Software — CashUp

**Escopo**: Responsabilidades das camadas, fluxo de dados unidirecional, desacoplamento e inversão de dependência.  
**Plataforma**: iOS 17+ nativo.  
**Stack Técnica**: Swift, SwiftUI, SwiftData, Combine, XCTest.  
**Padrão de Referência**: **Clean MVVM com Protocols Layer & Constructor Dependency Injection** (inspirado no padrão Layer-First com Repository Protocols do `c18-api`).  

---

## 1. Visão Geral da Arquitetura

O **CashUp** adota uma arquitetura limpa, desacoplada e estritamente testável. Para evitar o anti-padrão de "Massive ViewModel" e chamadas diretas e espalhadas de `ModelContext` por toda a interface, o sistema organiza o fluxo de dados em camadas bem delimitadas:

```
                  ┌────────────────────────────────────────┐
                  │              SwiftUI View              │
                  │        (Declaração e UI State)         │
                  └────────────────────────────────────────┘
                                       │
                                       ▼ Bindings / Ações
                  ┌────────────────────────────────────────┐
                  │          ViewModel (@MainActor)        │
                  │   (Formatação, Estados de Tela, Sinks) │
                  └────────────────────────────────────────┘
                                       │
                                       ▼ Executa casos de uso / orquestração
                  ┌────────────────────────────────────────┐
                  │          Domain Service / Protocol     │
                  │      (Regras de Domínio e Validação)   │
                  └────────────────────────────────────────┘
                                       │
                     ┌─────────────────┴─────────────────┐
                     │ Conforma com                      │ Conforma com
                     ▼                                   ▼
        ┌─────────────────────────┐         ┌─────────────────────────┐
        │ SwiftData Repository    │         │ InMemory Mock Repository│
        │   (Produção / App)      │         │   (Testes de Unidade)   │
        └─────────────────────────┘         └─────────────────────────┘
                     │
                     ▼ ModelContext CRUD
        ┌─────────────────────────┐
        │        SwiftData        │
        │ (SQLite Database Local) │
        └─────────────────────────┘
```

---

## 2. Comparativo Conceitual: CashUp vs. c18-api

A mesma disciplina de camadas que garante a estabilidade de uma API corporativa (`c18-api`) é aplicada no aplicativo mobile do CashUp:

| Camada no `c18-api` (API Backend) | Camada Equivalente no `CashUp` (Mobile iOS) | Responsabilidade |
|---|---|---|
| `Routes` & `Controllers` | **SwiftUI Views & Components** | Captura eventos de entrada, renderiza layout e delega execução. |
| `Services` (Regras de Negócio) | **ViewModels & UseCases** | Aplica regras de validação (RN-01 a RN-18), calcula métricas e orquestra fluxos. |
| `Protocols` (`src/protocols/`) | **Swift Protocols (`RepositoryProtocol`)** | Contratos de interface que desacoplam o domínio da tecnologia de banco. |
| `Repositories` (`src/repositories/`) | **SwiftData Repositories (`DataRepository`)** | Executa queries, inserts, updates e deletes com `FetchDescriptor` e `#Predicate`. |
| `Prisma Client` / PostgreSQL | **SwiftData (`ModelContext`)** | Mecanismo de persistência física dos objetos de dados. |
| `Zod Schemas` & DTOs | **Displayable / Form DTOs** | Estruturas de dados sanitizadas e formatadas para a interface. |
| Testes com `InMemoryRepository` | **Testes com `isStoredInMemoryOnly: true`** | Testes de unidade ultra-rápidos sem persistência em disco ou efeitos colaterais. |

---

## 3. Responsabilidade de Cada Camada

### 3.1 Views (`CashUp/Views/`)
- Declarativas, orientadas a componentes pequenos e reutilizáveis (`Componentes/`).
- Não executam lógica de negócio, cálculos matemáticos ou mutações de banco diretamente.
- Consomem o ViewModel via `@ObservedObject`, `@StateObject` ou injeção de ambiente.
- Estilos, espaçamentos e ícones seguem estritamente as diretrizes de design do iOS (Human Interface Guidelines).

### 3.2 ViewModels (`CashUp/Views/<Domain>/<Domain>ViewModel.swift`)
- Classes anotadas obrigatoriamente com `@MainActor` para assegurar que qualquer mutação de estado publicada ocorra na thread principal de interface.
- Exigem injeção de dependência via construtor (`init`).
- Expõem propriedades reativas `@Published` para que a View reaja a mudanças.
- Executam a conversão de dados brutos do modelo para dados de exibição formatados (`DisplayableExpense`, `CategoriaResumo`).

### 3.3 Protocolos de Repositório (`CashUp/Protocols/`)
- Definem contratos explícitos para operações de dados.
- Permitem que qualquer ViewModel seja testado isoladamente injetando um mock ou um repositório em memória sem tocar no disco.

```swift
// Exemplo de Protocolo de Repositório (src/Protocols/ExpenseRepositoryProtocol.swift)
protocol ExpenseRepositoryProtocol: Sendable {
    func fetchExpenses(for interval: DateInterval) async throws -> [ExpenseModel]
    func insert(_ expense: ExpenseModel) async throws
    func delete(_ expense: ExpenseModel) async throws
    func save() async throws
}
```

### 3.4 Persistência e SwiftData (`CashUp/Models/`)
- Entidades anotadas com `@Model`.
- Configurações de relacionamentos explícitas (`@Relationship(deleteRule: .cascade)`).
- Chaves primárias com UUIDs imutáveis (`@Attribute(.unique)`).
- Propriedades calculadas leves diretamente nos modelos (ex.: `valorTotalPlanejado`, `generateOccurrences`).

---

## 4. Reatividade e Sincronização Temporal (Combine)

O aplicativo mantém três áreas principais sincronizadas em relação ao mês ativo:
1. **Home (Dashboard)**: Métricas consolidadas do mês.
2. **Despesas**: Listagem de transações registradas no mês.
3. **Planejamento**: Orçamento alocado para o mês.

### Mecanismo de Pipeline do Combine:
```swift
// Setup de binding reativo entre ViewModels
planningViewModel.$currentMonth
    .removeDuplicates()
    .receive(on: RunLoop.main)
    .sink { [weak self] newMonth in
        guard let self = self else { return }
        let normalized = newMonth.startOfMonth()
        if self.currentMonth.startOfMonth() != normalized {
            self.currentMonth = normalized
        }
    }
    .store(in: &cancellables)
```

- **`removeDuplicates()`**: Evita loops de feedback reativo entre os ViewModels.
- **`startOfMonth()`**: Normaliza a data para o primeiro segundo do primeiro dia do mês.
- **`receive(on: RunLoop.main)`**: Garante entrega síncrona com o ciclo de renderização do SwiftUI.

---

## 5. Estratégia de Isolamento para Testes de Unidade

Seguindo o princípio de Zero Side Effects, os testes unitários do CashUp instanciam o `ModelContainer` isolado em memória:

```swift
// Padrão de Setup em Testes Unitários (CashUpUnitTests)
override func setUpWithError() throws {
    try super.setUpWithError()
    let schema = Schema([
        CategoriaModel.self,
        SubcategoriaModel.self,
        ExpenseModel.self,
        CategoriaPlanejadaModel.self,
        SubcategoriaPlanejadaModel.self
    ])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: configuration)
    self.context = ModelContext(container)
    self.viewModel = ExpensesViewModel(modelContext: self.context)
}
```

Isso garante:
- **Velocidade**: Execução de centenas de testes em poucos milissegundos.
- **Reprodutibilidade**: Cada caso de teste inicia com banco limpo e previsível.
- **Independência**: Testes não interferem na base de dados real do simulador ou do device.

---

## 6. Diretrizes de Concorrência e Tratamento de Erros

1. **Proteção de UI Thread**: Toda classe de ViewModel deve ser declarada como `@MainActor`.
2. **Zero FatalErrors em Produção**: Eliminar chamadas de `fatalError()` em fluxos de banco normais; falhas de I/O devem ser capturadas e tratadas com feedback gracioso para o usuário.
3. **Fallback Resiliente de ModelContainer**: Em caso de falha de migração no `CashUpApp.swift`, aplicar fallback seguro em memória para evitar que o app feche na inicialização.
