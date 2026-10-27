# Plano de Implementação: E0 — Fundação de Dados

**Escopo**: Preparar o schema do SwiftData para todas as features da Fase 1 e para o iCloud da Fase 2: migração versionada, dinheiro em centavos, contas e transferências, schema sem `@Attribute(.unique)`, deduplicação determinística e store em App Group.  
**Origem**: Item E0 de [`product_overview_roadmap.md`](../rules/product_overview_roadmap.md)  
**Princípio**: a E0 **não muda nada visível** para o usuário. Toda a entrega é estrutural e precisa ser provada por testes de migração.  
**Modelos envolvidos**: `CategoriaModel`, `SubcategoriaModel`, `ExpenseModel`, `CategoriaPlanejadaModel`, `SubcategoriaPlanejadaModel` e o novo `ContaModel`.

---

## Status de Execução

| Sub-etapa | Status | Data | Observações |
|---|---|---|---|
| E0.1 | ✅ Concluída | 2026-10-27 | PR #40. 198 testes unitários verdes (+5: `MigracaoUnitTests`). `SchemaV1` (cópia do `main`) e `SchemaV2` (modelos do `develop`) com estágio leve; `typealias` em `ModelosAtuais.swift`; `CashUpPersistence` como fábrica do container do app. A fixture cria o store sem versão, como o `main`. Validação manual feita: build do `main` com dados e build da branch instalado por cima, sem perda. Testes de UI não rodam no simulador iOS 27 (falha de ambiente pré-existente). |
| E0.2 | 🚧 Em andamento | — | Branch `refactor/e0-2-deduplicacao`. |
| E0.3 | ⏳ Pendente | — | — |
| E0.4 | ⏳ Pendente | — | — |
| E0.5 | ⏳ Pendente | — | — |

---

## Sumário

1. [Achados que mudam o desenho](#1-achados-que-mudam-o-desenho)
2. [Deduplicação sem `@Attribute(.unique)`](#2-deduplicação-sem-attributeunique)
3. [Versões do schema e estágios de migração](#3-versões-do-schema-e-estágios-de-migração)
4. [Sub-etapas (um PR cada)](#4-sub-etapas-um-pr-cada)
5. [Suíte de testes](#5-suíte-de-testes)
6. [Riscos e casos de borda](#6-riscos-e-casos-de-borda)
7. [Decisões (27/10/2026)](#7-decisões-27102026)

---

## 1. Achados que mudam o desenho

### 1.1 O schema de `develop` já diverge do publicado

A versão da App Store (1.5) corresponde ao `main` (último commit em 10/03/2026). Desde então, `develop` mudou o schema **sem versionamento**:

| Modelo | `main` (publicado) | `develop` |
|---|---|---|
| `ExpenseModel.id` | sem `.unique` | `@Attribute(.unique)` |
| `ExpenseModel.categoria` / `.subcategoria` | relacionamento simples | `@Relationship(deleteRule: .nullify)` |
| `CategoriaModel.transacoes` | não existe | inversa com `.nullify` |
| `SubcategoriaModel.transacoes` | não existe | inversa com `.nullify` |

**Consequência**: o `SchemaV1` precisa ser uma cópia fiel do `main`, não do `develop`. O primeiro estágio (V1 → V2) documenta as mudanças que o `develop` já fez. Se o store de um usuário da 1.5 não abrir, o `CashUpApp.makeContainer` cai no fallback em memória e **o usuário perde o acesso aos dados**. É o pior cenário possível.

### 1.2 O seed ressuscita o que o usuário apagou (bug existente)

`popularDadosIniciaisSeNecessario` roda a cada `HomeView.task` e recria qualquer categoria ou subcategoria do seed cujo `id` não exista. Só a Renda é protegida (`CategoriaEditorViewModel.apagarCategoria`). Então, quando o usuário apaga "Transporte" (sem transações), ela volta na próxima abertura. Isso também contradiz a RN-08, que diz que as categorias padrão não podem ser apagadas, enquanto o código permite.

Com o iCloud, o problema piora: um segundo aparelho vazio roda o seed e devolve a categoria apagada para o primeiro aparelho.

### 1.3 Hoje o `.unique` faz upsert, e o código não depende disso

Com `.unique`, inserir um modelo com `id` existente **atualiza** em vez de duplicar. Fora do seed, todos os `init` de modelo usam `UUID()` novo (`ExpensesViewModel`, `PlanningViewModel`, `RecommendedPlanningViewModel`, `CategoriaEditorViewModel`). O seed já checa os IDs antes de inserir. Remover o `.unique` não quebra nenhum fluxo atual.

O inverso também foi verificado para o estágio V1 → V2, que **adiciona** `.unique` em `ExpenseModel.id`: no `main`, o único ponto que cria transações (`AddTransactionViewModel`) usa o `UUID()` padrão, então um store da 1.5 não tem `id` repetido e a restrição nova não conflita com os dados existentes.

---

## 2. Deduplicação sem `@Attribute(.unique)`

### 2.1 De onde viriam duplicatas

| Origem | Quando | Exemplo |
|---|---|---|
| Seed em dois aparelhos | Fase 2 (iCloud) | iPhone e Mac rodam o seed antes do primeiro sync; depois do sync existem 2 "Transporte" com o mesmo `SeedIDs.idTransporte` |
| Restaurar backup | E9 | Importar um backup sobre dados que já existem |
| Dois contextos rodando o seed | Hoje: impossível | O seed é `@MainActor` e não tem `await` interno, então não intercala. A regra é **manter assim** |

Localmente, durante a E0, nada gera duplicata. A deduplicação entra na E0 porque o schema perde a proteção agora, e o serviço precisa estar pronto e testado antes de o iCloud ser ligado.

### 2.2 Estratégia em três camadas

**Camada 1: prevenir (seed versionado com lápides)**

- O seed passa a ter versão (`SeedCatalogo.versao`). O app grava a última versão aplicada em `AppSettingsProtocol` (`seedVersaoAplicada`).
- **Store vazio**: aplica o catálogo inteiro.
- **Versão nova do catálogo**: insere só os itens marcados com `introduzidoNaVersao > seedVersaoAplicada`. Itens antigos que não existem mais **não são recriados**, porque o usuário os apagou. Isso corrige o achado 1.2.
- **Lápide sincronizável**: apagar um item do seed cria um `SeedRemocaoModel(seedID)`. Ele vai junto no iCloud, para outro aparelho saber que aquele item foi apagado de propósito.

**Camada 2: corrigir (serviço de deduplicação determinística)**

`DeduplicacaoService` (protocolo `DeduplicacaoServiceProtocol`) é idempotente e executa, nesta ordem, num único `save()`:

| Passo | Agrupa por | Sobrevivente | O que migra dos perdedores |
|---|---|---|---|
| 1. Categorias | `id` | menor `(criadoEm, instanciaID)` | `subcategorias`, `transacoes`, `CategoriaPlanejadaModel.categoriaOriginal` |
| 2. Subcategorias | `id` | menor `(criadoEm, instanciaID)` | `transacoes`, `SubcategoriaPlanejadaModel.subcategoriaOriginal`; `usageCount` somado |
| 3. Lápides | `SeedRemocaoModel.seedID` | — | Remove o item do seed se ele **não tiver transações**. Se tiver, a lápide é descartada, porque o uso real vence a remoção |
| 4. Categoria planejada | `(mesAno, categoriaOriginal.id)` (RN-09) | menor `(criadoEm, instanciaID)` | `subcategoriasPlanejadas` |
| 5. Subcategoria planejada | `(categoriaPlanejada, subcategoriaOriginal.id)` (RN-10) | menor `(criadoEm, instanciaID)` | — (o valor vem da regra de campos abaixo) |
| 6. Transações | `id` | menor `(criadoEm, instanciaID)` | — (só aparecem por restauração de backup) |

**Por que o sobrevivente precisa de `instanciaID`**: os dois aparelhos rodam a deduplicação ao mesmo tempo. Se cada um escolhesse um sobrevivente diferente (o "primeiro que achou", por exemplo), um apagaria o sobrevivente do outro e as transações reapontadas se perderiam. O par `(criadoEm, instanciaID)` é gravado no registro e sincronizado, então todos os aparelhos que já viram as duas cópias escolhem **o mesmo** sobrevivente. `instanciaID` é um `UUID()` novo por registro físico: duas cópias com o mesmo `id` sempre têm `instanciaID` diferentes.

**Regra de campos editáveis** (`nome`, `icon`, cor, `valorPlanejado`): a identidade fica com o sobrevivente, mas os valores vêm da cópia com o maior `atualizadoEm`. Assim, uma renomeação feita no aparelho "perdedor" não se perde.

**Fora da E0**: categorias personalizadas com **nomes** iguais e IDs diferentes (o usuário criou "Pets" no iPhone e também no Mac). A E0 deduplica só por `id`. A regra por nome é decidida no plano da F1 (ver seção 7).

**Camada 3: quando rodar**

| Momento | Fase |
|---|---|
| No `didMigrate` do estágio que remove o `.unique` | E0 |
| Logo após o seed, na abertura do app | E0 |
| Após cada importação do CloudKit | F1 |
| Após restaurar um backup | E9 |

O seed sai da `HomeView.task` e passa a rodar uma única vez por abertura, em `RootView`, antes de mostrar a Home. Tudo continua no `@MainActor`.

### 2.3 Campos novos de suporte

Em `CategoriaModel`, `SubcategoriaModel`, `CategoriaPlanejadaModel`, `SubcategoriaPlanejadaModel` e `ExpenseModel`:

```swift
var instanciaID: UUID = UUID()
var criadoEm: Date = Date.distantPast
var atualizadoEm: Date = Date.distantPast
```

`Date.distantPast` como default faz os registros migrados empatarem no `criadoEm`, e o desempate vai para o `instanciaID`. Registros novos recebem `Date()` no `init`. `atualizadoEm` é atualizado pelos ViewModels em toda edição.

---

## 3. Versões do schema e estágios de migração

As classes passam a viver dentro de `enum SchemaVn: VersionedSchema`. O app usa `typealias` para a versão atual (`typealias ExpenseModel = SchemaV5.ExpenseModel`), então o restante do código não muda de nome.

| Versão | Conteúdo | Estágio | Sub-etapa |
|---|---|---|---|
| **V1** | Cópia fiel do `main` (App Store 1.5) | — | E0.1 |
| **V2** | Mudanças que o `develop` já fez (inversas `transacoes`, `.unique` em `ExpenseModel`) | leve (lightweight) | E0.1 |
| **V3** | Sem `.unique`; to-many opcionais (`[X]?`); `instanciaID`, `criadoEm`, `atualizadoEm`; `SeedRemocaoModel` | custom: `didMigrate` roda a deduplicação | E0.2 |
| **V4** | `amountInCents: Int64` e `valorPlanejadoCentavos: Int64` **ao lado** dos `Double` | custom: `didMigrate` converte `(valor * 100).rounded()` | E0.3 |
| **V5** | Remove `amount: Double` e `valorPlanejado: Double`; adiciona `ContaModel`, `ExpenseModel.conta`, `ExpenseModel.contaDestino`, `ExpenseModel.tipoRaw` | custom: `didMigrate` cria a conta "Carteira", liga todas as transações a ela e define o tipo a partir de `isIncome` | E0.4 |

**Por que V4 e V5 separados**: o `didMigrate` da V4 precisa ler o `Double` antigo e escrever o centavo novo no mesmo registro. Só um estágio seguinte pode remover o campo antigo com segurança.

**Por que to-many opcionais já na V3**: é exigência do CloudKit. Mudar isso depois do iCloud ligado seria mais caro.

---

## 4. Sub-etapas (um PR cada)

### E0.1 — Infraestrutura de versionamento (sem mudar comportamento)

**Criar**
- `CashUp/Models/Schema/SchemaV1.swift` — modelos copiados do `main`
- `CashUp/Models/Schema/SchemaV2.swift` — modelos atuais do `develop`
- `CashUp/Models/Schema/CashUpMigrationPlan.swift` — `SchemaMigrationPlan` com `.lightweight(V1 → V2)`
- `CashUp/Models/Schema/ModelosAtuais.swift` — `typealias SchemaAtual` e um `typealias` por modelo apontando para a versão atual
- `CashUp/Models/Schema/CashUpPersistence.swift` — fábrica única do `ModelContainer` (schema atual + plano de migração), usada pelo app e pelos testes de migração
- `CashUpUnitTests/Migracao/MigracaoUnitTests.swift`

**Modificar**
- `CashUpApp.makeContainer` — passa a usar `CashUpPersistence.makeContainer(inMemory:)`
- `CashUp/Models/*.swift` — as classes passam para dentro de `extension SchemaV2`; extensões e computadas continuam funcionando pelos `typealias`

**Fixture**: os testes criam o store V1 em disco com os modelos do `SchemaV1` (cópia fiel do `main`) e reabrem pela fábrica do app. O store é criado com `Schema(SchemaV1.models)`, **sem** `VersionedSchema`, como o `main` fazia: o SwiftData precisa reconhecer um store sem versão como V1 pelos hashes das entidades, e é esse o caso do usuário da 1.5. Como validação extra, antes do merge: instalar o build do `main` no simulador, registrar dados, instalar o build da branch por cima e conferir que nada sumiu.

**Pronto quando**: o store da 1.5 abre sem cair no fallback e todas as contagens e somas batem com as do store V1 criado no teste.

### E0.2 — Sem `.unique`, seed versionado e deduplicação

**Criar**
- `CashUp/Models/Schema/SchemaV3.swift` (inclui `SeedRemocaoModel`)
- `CashUp/Services/Persistencia/DeduplicacaoServiceProtocol.swift`
- `CashUp/Services/Persistencia/DeduplicacaoService.swift`
- `CashUp/Services/Persistencia/SeedService.swift` — o catálogo sai de `SeedData.swift`, ganha `versao` e `introduzidoNaVersao`
- `CashUpUnitTests/Persistencia/DeduplicacaoUnitTests.swift`
- `CashUpUnitTests/Persistencia/SeedServiceUnitTests.swift`

**Modificar**
- `CashUpMigrationPlan` — estágio custom V2 → V3
- `AppSettingsProtocol` / `UserDefaultsAppSettings` — `seedVersaoAplicada`
- `CategoriaEditorViewModel` — apagar um item do seed cria `SeedRemocaoModel`; toda edição atualiza `atualizadoEm`
- `RootView` — roda seed e deduplicação uma vez, antes da Home
- `HomeView` — remove a chamada do seed
- Usos de `categoria.subcategorias` e `.transacoes`, que passam a ser opcionais (`?? []`)

**Pronto quando**: os testes da seção 5 passam, uma categoria do seed apagada não volta após reabrir o app, e o store da 1.5 migra até a V3.

### E0.3 — Dinheiro em centavos

**Criar**
- `CashUp/Models/Schema/SchemaV4.swift`
- `CashUp/Sources/Extensions/Formatters/Centavos.swift` — conversões `Int64 ↔ Decimal` e formatação (substitui o uso de `Double` no `BRLCurrencyFormatter`)

**Modificar**
- `CashUpMigrationPlan` — estágio custom V3 → V4
- Leitura e soma de valores em `HomeViewModel`, `ExpensesViewModel`, `PlanningViewModel`, `RecommendedPlanningService`, `SmartFinancialCoachEngine`, `TipsViewModel` (`FiftyThirtyTwentyBreakdown`) e campos de entrada (`CurrencyAmountField`, `CompactCurrencyTextField`). As somas passam a ser feitas em `Int64`, e o `Double` fica só na fronteira com o Swift Charts.
- `docs/rules/business_rules.md` — RN-01

**Pronto quando**: o total do mês na fixture é idêntico, centavo por centavo, antes e depois da migração; um teste de soma de 0,10 + 0,20 resulta em exatamente 30 centavos.

### E0.4 — Contas, tipo de lançamento e remoção dos `Double`

**Criar**
- `CashUp/Models/Schema/SchemaV5.swift` (`ContaModel`, `TipoLancamento`, `TipoConta`)
- `CashUp/Protocols/Conta/ContaRepositoryProtocol.swift`
- `CashUp/Repositories/Conta/SwiftDataContaRepository.swift`
- `CashUpUnitTests/Conta/ContaRepositoryUnitTests.swift`

**Modificar**
- `CashUpMigrationPlan` — estágio custom V4 → V5
- `ExpensesViewModel` — todo lançamento novo vai para a conta padrão. O seletor de conta só aparece na E2, e a regra "transferência não entra em totais" já vale nas métricas
- `HomeViewModel` e métricas da RN-14 — filtram `tipo != .transferencia`
- `docs/rules/business_rules.md` — RN-02 e RN-03

**Pronto quando**: o store da 1.5 migra até a V5 com todas as transações na "Carteira", e os totais da Home não mudam.

### E0.5 — Store no App Group

**Criar**
- Entitlement `com.apple.security.application-groups` com `group.<bundle-id>`
- `CashUp/Services/Persistencia/StoreLocationMigrator.swift` — se o store antigo existe e o do grupo não, copia `default.store`, `-wal` e `-shm` para o container do grupo **antes** de abrir o `ModelContainer`. O arquivo antigo só é apagado depois de o container novo abrir com sucesso.

**Modificar**
- `CashUpApp.makeContainer` — `ModelConfiguration(groupContainer: .identifier(...))`

**Pronto quando**: o upgrade com o store no local antigo preserva os dados, e reabrir o app não copia o store de novo.

---

## 5. Suíte de testes

Tudo em memória, exceto os testes de migração, que copiam a fixture para um diretório temporário.

| Teste | Garante |
|---|---|
| `testMigraStore1_5AteVersaoAtual` | Contagens de categorias, subcategorias, transações e planejamentos iguais às da fixture |
| `testMigracaoPreservaRecorrencias` | `repetition`, `endDate` e `excludedDates` intactos |
| `testMigracaoCentavosExatos` | Soma em centavos == soma original arredondada, por transação e por mês |
| `testDeduplicaCategoriaReapontaTransacoes` | Duas "Transporte" com o mesmo `id` viram uma só, e todas as transações apontam para ela |
| `testSobreviventeEhDeterministico` | Mesmo resultado em qualquer ordem de fetch (embaralhar 100 vezes) |
| `testCamposVemDoMaisRecente` | Renomear a cópia perdedora preserva o nome novo |
| `testSomaUsageCount` | `usageCount` do sobrevivente = soma das cópias |
| `testDeduplicaPlanejamentoDoMesmoMes` | RN-09 e RN-10 voltam a valer depois do merge |
| `testDeduplicacaoIdempotente` | Rodar duas vezes não muda nada na segunda |
| `testLapideRemoveSeedSemTransacoes` | Item apagado em outro aparelho some daqui |
| `testLapideNaoRemoveSeedComTransacoes` | Uso real vence a remoção |
| `testSeedNaoRessuscitaItemApagado` | Corrige o achado 1.2 |
| `testSeedNovaVersaoAdicionaSoItensNovos` | Versão nova do catálogo não recria itens antigos |
| `testTransferenciaForaDosTotais` | RN-14 com o tipo novo |
| `testStoreCopiadoParaAppGroup` | E0.5 |

Testes de UI: a suíte atual precisa continuar verde, sem nenhum teste novo, porque a E0 não muda telas.

---

## 6. Riscos e casos de borda

| Risco | Mitigação |
|---|---|
| Fixture não representa os stores reais | Gerar a fixture com o build exato do `main`, incluindo recorrência com `excludedDates` e categoria personalizada |
| `didMigrate` falha no meio | Cada estágio custom só chama `save()` no fim. O comportamento do SwiftData quando um estágio lança erro precisa ser confirmado por um teste dedicado (`testFalhaNoDidMigrateNaoCorrompeStore`). O resultado esperado é o store continuar na versão anterior e o app mostrar o aviso atual, em vez de abrir vazio |
| Valores `Double` com ruído (ex.: `19.899999`) | `(valor * 100).rounded(.toNearestOrAwayFromZero)` |
| Transação sem categoria (anulada por exclusão) | A deduplicação ignora referências nulas. A migração não cria categoria para elas |
| Store grande deixa a primeira abertura lenta | Medir com uma fixture de 5 mil transações. O alvo é menos de 2 s no iPhone mais antigo suportado |

---

## 7. Decisões (27/10/2026)

1. **TestFlight**: nenhum build de `develop` foi distribuído. Os únicos stores reais estão no formato do `main` (V1).
2. **`usageCount` no merge**: soma das cópias. O DT-04 continua como débito separado.
3. **RN-08**: atualizar a regra para refletir o código. Categorias padrão podem ser apagadas (menos Renda), e as lápides garantem que o item apagado não volta. A atualização entra no PR da E0.2.
4. **Nomes duplicados entre aparelhos**: decididos no plano da F1. A E0 deduplica só por `id`.
