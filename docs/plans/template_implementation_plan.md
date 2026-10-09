# Implementation Plan Template & Specification Guide — CashUp

**Escopo**: Template canônico e guia arquitetural para desenvolvedores e assistentes de IA elaborarem planos de implementação de novos módulos, entidades e telas no aplicativo **CashUp**.  
**Padrão**: Clean MVVM com Camada de Protocolos de Repositório, Injeção de Dependências por Construtor, Testes Isolados em Memória e Zero Comentários no Código (Clean Code).  
**Referências**: [`docs/rules/architecture.md`](../rules/architecture.md), [`docs/rules/business_rules.md`](../rules/business_rules.md), [`docs/rules/project_structure.md`](../rules/project_structure.md), [`docs/rules/product_vision.md`](../rules/product_vision.md).  
**Alinhamento Metodológico**: Adaptação direta do padrão de alta fidelidade utilizado no repositório `c18-api` para a arquitetura nativa iOS (Swift, SwiftUI, SwiftData, Combine).  

> [!IMPORTANT]
> **Diretrizes Obrigatórias para a IA na Elaboração e Execução de Planos:**
> 1. **Zero Comentários no Código (Clean Code)**: Nunca gere comentários redundantes (`//`, `/* */`) em arquivos `.swift`. O código deve ser 100% legível por meio de nomes significativos, funções curtas e tipagem estrita.
> 2. **Política de Git**: O assistente **nunca executa commits** (`git commit` é ação estritamente manual do desenvolvedor).
> 3. **Inversão de Dependência**: Os ViewModels nunca devem instanciar queries brutas acopladas; dependem de protocolos (`*RepositoryProtocol`) injetados via `init`.
> 4. **Isolamento Total em Testes**: Todo plano deve conter suíte de testes unitários executada com `ModelConfiguration(isStoredInMemoryOnly: true)`, sem tocar no disco ou interferir no ambiente de produção.
> 5. **Zero FatalErrors**: Eliminar chamadas de `fatalError()` em fluxos de negócio e persistência; erros devem ser tipados (`enum CashUpDomainError: LocalizedError`) e propagados graciosamente para a interface.
> 6. **Validação Rigorosa**: Validar dados antes de tentar persistir (valores `> 0`, integridade referencial, datas limites).

---

## Instruções para o Assistente ao Redigir um Novo Plano

Ao ser solicitado a criar o plano de implementação de uma nova feature ou módulo, copie a estrutura abaixo e preencha integralmente:
- Substitua `<Domain>` pelo domínio alvo (`Categoria`, `Meta`, `Relatorio`, `Notificacao`, `Biometria`, `Transacao`, etc.).
- Substitua `<Resource>` pelo nome da entidade/modelo correspondente (`GoalModel`, `NotificationConfig`, `ExportReport`, etc.).
- Preencha cada seção detalhadamente com assinaturas de protocolos, estruturas de dados, regras de negócio e testes automatizados.

---

# [INÍCIO DO TEMPLATE]

# Plano de Implementação: Módulo — `<Nome do Módulo>` (`<Resource>`)

**Escopo**: Implementação completa de modelos SwiftData, protocolos de repositório, repositório concreto, lógica de negócio / ViewModel, componentes e telas SwiftUI, testes unitários isolados e testes de interface para `<Resource>`.  
**Domínio Alvo**: `<Domain>`  
**Modelos Envolvidos**: `<ResourceModel>`, `<RelatedModel>`  

---

## Sumário

1. [Arquivos a Criar / Modificar](#1-arquivos-a-criar--modificar)
2. [Modelos de Domínio SwiftData (`Models/<Domain>/`)](#2-modelos-de-domínio-swiftdata)
3. [Protocolos de Repositório (`Protocols/<Domain>/`)](#3-protocolos-de-repositório)
4. [Repositórios Concretos (`Repositories/<Domain>/`)](#4-repositórios-concretos)
5. [ViewModels e Regras de Negócio (`Views/<Domain>/` ou `ViewModels/`)](#5-viewmodels-e-regras-de-negócio)
6. [Telas e Componentes SwiftUI (`Views/<Domain>/`)](#6-telas-e-componentes-swiftui)
7. [Suíte de Testes Unitários (`CashUpUnitTests/<Domain>/`)](#7-suíte-de-testes-unitários)
8. [Suíte de Testes de Interface (`CashUpUITests/<Domain>/`)](#8-suíte-de-testes-de-interface)
9. [Mapeamento de Erros e Casos de Borda](#9-mapeamento-de-erros-e-casos-de-borda)
10. [Tabela Resumo de Funcionalidades e Ações](#10-tabela-resumo-de-funcionalidades-e-ações)
11. [Ordem de Execução Passo a Passo (Dependency-Ordered)](#11-ordem-de-execução-passo-a-passo)

---

## 1. Arquivos a Criar / Modificar

```
CashUp/
├── Models/<Domain>/
│   └── <Resource>Model.swift                  ← Modelo persistido @Model SwiftData
├── Protocols/<Domain>/
│   └── <Resource>RepositoryProtocol.swift     ← Contrato de abstração de dados
├── Repositories/<Domain>/
│   └── <Resource>Repository.swift             ← Implementação concreta com ModelContext
├── Views/<Domain>/
│   ├── <Resource>ViewModel.swift              ← Gerenciador de estado (@MainActor)
│   ├── <Resource>View.swift                   ← Tela principal SwiftUI
│   └── Componentes/
│       └── <Resource>RowView.swift            ← Componente modular de interface
CashUpUnitTests/<Domain>/
└── <Resource>UnitTests.swift                  ← Testes de unidade em memória (isStoredInMemoryOnly)
CashUpUITests/<Domain>/
└── <Resource>UITests.swift                    ← Testes de fluxo e navegação automatizada
```

---

## 2. Modelos de Domínio SwiftData (`Models/<Domain>/`)

Definição do modelo de entidade com chave primária UUID única e regras de relacionamento explícitas:

```swift
import SwiftData
import Foundation

@Model
final class <Resource>Model {
    @Attribute(.unique)
    var id: UUID
    var nome: String
    var valor: Double
    var dataCriacao: Date
    var ativo: Bool

    init(
        id: UUID = UUID(),
        nome: String,
        valor: Double,
        dataCriacao: Date = Date(),
        ativo: Bool = true
    ) {
        self.id = id
        self.nome = nome
        self.valor = valor
        self.dataCriacao = dataCriacao
        self.ativo = ativo
    }
}
```

---

## 3. Protocolos de Repositório (`Protocols/<Domain>/`)

Contrato formal que desacopla o ViewModel da tecnologia de armazenamento:

```swift
import Foundation

protocol <Resource>RepositoryProtocol: Sendable {
    func fetchAll() async throws -> [<Resource>Model]
    func fetchById(_ id: UUID) async throws -> <Resource>Model?
    func insert(_ item: <Resource>Model) async throws
    func delete(_ item: <Resource>Model) async throws
    func save() async throws
}
```

---

## 4. Repositórios Concretos (`Repositories/<Domain>/`)

Implementação baseada em SwiftData utilizando `ModelContext`:

```swift
import Foundation
import SwiftData

final class <Resource>Repository: <Resource>RepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() async throws -> [<Resource>Model] {
        let descriptor = FetchDescriptor<<Resource>Model>(
            sortBy: [SortDescriptor(\.dataCriacao, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchById(_ id: UUID) async throws -> <Resource>Model? {
        let predicate = #Predicate<<Resource>Model> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func insert(_ item: <Resource>Model) async throws {
        context.insert(item)
        try context.save()
    }

    func delete(_ item: <Resource>Model) async throws {
        context.delete(item)
        try context.save()
    }

    func save() async throws {
        try context.save()
    }
}
```

---

## 5. ViewModels e Regras de Negócio (`Views/<Domain>/`)

Gerenciador de estado observável protegido por `@MainActor`, com injeção do repositório:

```swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class <Resource>ViewModel: ObservableObject {
    private let repository: <Resource>RepositoryProtocol

    @Published var items: [<Resource>Model] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert: Bool = false

    init(repository: <Resource>RepositoryProtocol) {
        self.repository = repository
    }

    func carregarDados() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.items = try await repository.fetchAll()
        } catch {
            self.errorMessage = "Falha ao carregar registros: \(error.localizedDescription)"
        }
    }

    func adicionarItem(nome: String, valor: Double) async throws {
        guard !nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CashUpDomainError.invalidName
        }
        guard valor > 0 else {
            throw CashUpDomainError.invalidAmount
        }

        let novoItem = <Resource>Model(nome: nome, valor: valor)
        try await repository.insert(novoItem)
        await carregarDados()
    }

    func removerItem(_ item: <Resource>Model) async throws {
        try await repository.delete(item)
        await carregarDados()
    }
}
```

---

## 6. Telas e Componentes SwiftUI (`Views/<Domain>/`)

Interface declarativa pura sem dependência direta do banco:

```swift
import SwiftUI

struct <Resource>View: View {
    @StateObject private var viewModel: <Resource>ViewModel

    init(viewModel: <Resource>ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.items) { item in
                    <Resource>RowView(item: item)
                }
                .onDelete { indexSet in
                    // deleção via viewModel
                }
            }
            .navigationTitle("<Nome do Módulo>")
            .task {
                await viewModel.carregarDados()
            }
        }
    }
}
```

---

## 7. Suíte de Testes Unitários (`CashUpUnitTests/<Domain>/`)

Testes de unidade com banco em memória estritamente isolado:

```swift
import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class <Resource>UnitTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var repository: <Resource>Repository!
    private var viewModel: <Resource>ViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([<Resource>Model.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        repository = <Resource>Repository(context: context)
        viewModel = <Resource>ViewModel(repository: repository)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        repository = nil
        viewModel = nil
        try super.tearDownWithError()
    }

    func testCriarItemComSucesso() async throws {
        try await viewModel.adicionarItem(nome: "Item Teste", valor: 150.0)
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.nome, "Item Teste")
        XCTAssertEqual(viewModel.items.first?.valor, 150.0)
    }

    func testRejeitarValorNegativoOuZero() async {
        do {
            try await viewModel.adicionarItem(nome: "Invalido", valor: 0.0)
            XCTFail("Deveria ter lançado erro de valor inválido")
        } catch {
            XCTAssertTrue(error is CashUpDomainError)
        }
    }

    func testRemoverItemAtualizaLista() async throws {
        try await viewModel.adicionarItem(nome: "Para Deletar", valor: 50.0)
        guard let item = viewModel.items.first else {
            XCTFail("Item não encontrado")
            return
        }

        try await viewModel.removerItem(item)
        XCTAssertTrue(viewModel.items.isEmpty)
    }
}
```

---

## 8. Suíte de Testes de Interface (`CashUpUITests/<Domain>/`)

Testes automatizados de UI via XCUITest com a flag `--uitesting`:

```swift
import XCTest

final class <Resource>UITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testFluxoCriacaoDeItemNaUI() throws {
        // 1. Navegar até a tela
        // 2. Tocar no botão de adicionar
        // 3. Preencher formulário e submeter
        // 4. Assegurar que o item aparece na List
    }
}
```

---

## 9. Mapeamento de Erros e Casos de Borda

| Cenário de Borda | Condição | Ação Esperada | Tratamento de Erro |
|---|---|---|---|
| **Valor Zerado ou Negativo** | `valor <= 0.0` | Bloqueia inserção | Dispara `CashUpDomainError.invalidAmount` com feedback visual |
| **Nome Vazio** | `nome.trimming.isEmpty` | Bloqueia formulário | Dispara `CashUpDomainError.invalidName` |
| **Duplicidade em Relação** | Item já existente no escopo | Alerta ou redirecionamento | Exibe aviso descritivo sem crash de banco |
| **Exclusão de Dependências** | Deleção de entidade com filhos | Cascade delete limpo | Aplica `deleteRule: .cascade` sem deixar registros órfãos |

---

## 10. Tabela Resumo de Funcionalidades e Ações

| Ação | Operação | Entrada | Saída / Efeito | Permissão / Regra |
|---|---|---|---|---|
| Listar | `fetchAll` | Filtros opcionais | `[<Resource>Model]` ordenado | Consulta segura |
| Inserir | `insert` | Payload validado | Novo registro persistido | `amount > 0`, nome preenchido |
| Excluir | `delete` | ID do registro | Remoção do banco | Atualiza contadores e listas |
| Atualizar | `save` | Campos alterados | Estado persistido | Notifica observadores |

---

## 11. Ordem de Execução Passo a Passo (Dependency-Ordered)

```
Passo 1 ─ Modelos SwiftData & Schema
  └── CashUp/Models/<Domain>/<Resource>Model.swift

Passo 2 ─ Protocolos de Repositório
  └── CashUp/Protocols/<Domain>/<Resource>RepositoryProtocol.swift

Passo 3 ─ Repositório Concreto
  └── CashUp/Repositories/<Domain>/<Resource>Repository.swift

Passo 4 ─ ViewModel & Regras de Negócio
  └── CashUp/Views/<Domain>/<Resource>ViewModel.swift

Passo 5 ─ Suíte de Testes Unitários Isolados
  └── CashUpUnitTests/<Domain>/<Resource>UnitTests.swift (Executar testes até ficarem verdes)

Passo 6 ─ Componentes e Telas SwiftUI
  ├── CashUp/Views/<Domain>/Componentes/<Resource>RowView.swift
  └── CashUp/Views/<Domain>/<Resource>View.swift

Passo 7 ─ Integração na Navegação Central
  └── Integrar na HomeView ou barra de navegação/menu

Passo 8 ─ Testes de Interface UI
  └── CashUpUITests/<Domain>/<Resource>UITests.swift
```

---

## Apêndice: Checklist de Qualidade de Implementação

Antes de considerar qualquer entrega concluída, confirme:
- [ ] **Clean Code**: Zero comentários redundantes em arquivos Swift.
- [ ] **Inversão de Dependências**: ViewModel consome apenas o Protocolo de Repositório.
- [ ] **Thread Safety**: ViewModel anotado obrigatoriamente com `@MainActor`.
- [ ] **Testes em Memória**: Suíte de testes unitários executada com container isolado em memória.
- [ ] **Sem Crashes Silenciosos**: Nenhum `fatalError()` desnecessário em código de produção.
- [ ] **Cascade Rules**: Configuração de deleção em cascata revisada no modelo SwiftData.
- [ ] **Formatação pt_BR**: Moeda e datas formatadas no padrão nacional.
- [ ] **Git Manual**: Nenhuma ação de commit automático pela IA.

# [FIM DO TEMPLATE]
