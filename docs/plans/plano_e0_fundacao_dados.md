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
| E0.2 | ✅ Concluída | 2026-10-27 | PR #41. 213 testes unitários verdes. Desvios do plano registrados em [E0.2 — notas de implementação](#e02--notas-de-implementação). |
| E0.3 | ✅ Concluída (PR #42) | 2026-10-31 | Branch `refactor/e0-3-centavos`. 245 testes unitários verdes (+32, já com as correções do review do PR #42). Dinheiro em `Int64` (centavos) em todo o app; estágio custom V3 → V4. Descobriu e corrigiu o caso de falha no `didMigrate` (store fica V4 com centavos zerados). Desvios em [E0.3 — notas de implementação](#e03--notas-de-implementação). Testes de UI não rodam no simulador iOS 27 (falha de ambiente pré-existente). |
| E0.4 | ✅ Concluída (PR #43) | 2026-10-31 | Branch `refactor/e0-4-contas`, empilhada na `refactor/e0-3-centavos` (PR #42). 283 testes unitários verdes (+28, mais os do review). Validação manual feita (upgrade do build V1 por cima, totais da Home, Carteira e lançamento novo). `ContaModel`, `TipoLancamento`, `TipoConta`, `ExpenseModel.conta`/`contaDestino`/`tipoRaw`; estágio custom V4 → V5; `Double` removidos. Desvios em [E0.4 — notas de implementação](#e04--notas-de-implementação). Testes de UI não rodam no simulador iOS 27 (falha de ambiente pré-existente). |
| E0.5 | ✅ Concluída (PR #44; validação em aparelho real pendente) | 2026-10-31 | Branch `refactor/e0-5-app-group`, empilhada na `refactor/e0-4-contas` (PRs #42 e #43). 308 testes unitários verdes (+25 sobre a E0.4, já com as correções do review). Entitlement de App Group, `StoreLocationMigrator` (cópia atômica com o diretório de dados externos do Core Data, antigo só apagado após abrir o novo e se não foi alterado depois da cópia) e `CashUpPersistence` abrindo no grupo, com fallback no local antigo e sentinela contra store vazio. Desvios e achados em [E0.5 — notas de implementação](#e05--notas-de-implementação). Validação manual no simulador já feita pelo usuário; roteiro e o que falta em [E0.5 — validação manual](#e05--validação-manual). Testes de UI não rodam no simulador iOS 27 (falha de ambiente pré-existente). |

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

#### E0.2 — notas de implementação

- **Deduplicação fora do `didMigrate`**: o estágio V2 → V3 só dá um `instanciaID` novo a cada registro (o default do schema vale para o store inteiro, então todos os registros migrados sairiam com o mesmo valor) e salva. O `DeduplicacaoService` trabalha com os modelos atuais (`typealias`); chamado de dentro de um estágio antigo, ele quebraria assim que a V4 existisse. Como a V2 tem `.unique` em todos os `id`, o store migrado não tem duplicatas, e a deduplicação roda logo depois, na abertura, junto com o seed.
- **Defaults em todos os atributos**: a V3 já dá default a todos os atributos armazenados, outra exigência do CloudKit (ver E0 no roadmap).
- **Usuário vindo da 1.5**: store com dados e sem `seedVersaoAplicada` é tratado como versão 1 do catálogo. Só entram itens das versões seguintes (hoje, a subcategoria Reserva, versão 2). Store vazio recebe o catálogo inteiro, menos os itens com lápide.
- **Lápides**: só itens do catálogo geram lápide. Apagar uma categoria do seed grava a lápide da categoria; as subcategorias somem por cascata e o seed não as recria sem a categoria. `SeedRemocaoModel` também tem `instanciaID`, para que todos os aparelhos fiquem com a mesma lápide quando houver cópias. A lápide da Renda é sempre descartada.
- **`atualizadoEm`**: atualizado nas edições de categoria e subcategoria (`CategoriaEditorViewModel`) e de `valorPlanejado` (`PlanningViewModel`, `RecommendedPlanningViewModel`).
- **`atualizadoEm` de transações**: os ViewModels de transação (`ExpensesViewModel`) ainda não atualizam o campo, e a deduplicação de transações mantém a cópia mais antiga sem comparar campos. Hoje não há perda; a comparação por `atualizadoEm` fica para a E9 (restauração de backup), que é quando uma edição mais nova poderia ser descartada.
- **Cópia do seed não é edição**: itens criados pelo `SeedService` nascem com `atualizadoEm = .distantPast`. No empate de `atualizadoEm`, a deduplicação escolhe a cópia de menor `(criadoEm, instanciaID)`, o que mantém o resultado igual em todos os aparelhos.
- **Renda e RN-08**: a aplicação de lápides não apaga a última subcategoria da Renda, e o seed insere a subcategoria geral numa Renda criada sem subcategorias.
- **Fora desta sub-etapa**: `testFalhaNoDidMigrateNaoCorrompeStore` (seção 6). O SwiftData não oferece um jeito limpo de injetar falha no estágio, então fica para a E0.3, o primeiro estágio custom que converte dados. (Feito na E0.3, com um plano de migração só de teste.)

### E0.3 — Dinheiro em centavos

**Criar**
- `CashUp/Models/Schema/SchemaV4.swift`
- `CashUp/Sources/Extensions/Formatters/Centavos.swift` — conversões `Int64 ↔ Decimal` e formatação (substitui o uso de `Double` no `BRLCurrencyFormatter`)

**Modificar**
- `CashUpMigrationPlan` — estágio custom V3 → V4
- Leitura e soma de valores em `HomeViewModel`, `ExpensesViewModel`, `PlanningViewModel`, `RecommendedPlanningService`, `SmartFinancialCoachEngine`, `TipsViewModel` (`FiftyThirtyTwentyBreakdown`) e campos de entrada (`CurrencyAmountField`, `CompactCurrencyTextField`). As somas passam a ser feitas em `Int64`, e o `Double` fica só na fronteira com o Swift Charts.
- `docs/rules/business_rules.md` — RN-01

**Pronto quando**: o total do mês na fixture é idêntico, centavo por centavo, antes e depois da migração; um teste de soma de 0,10 + 0,20 resulta em exatamente 30 centavos.

#### E0.3 — notas de implementação

- **V3 congelada**: até a E0.2 as classes da V3 viviam em `CashUp/Models/*.swift` (`extension SchemaV3`). Para existir uma V4 distinta, a V3 foi copiada (só os atributos armazenados e relacionamentos) para dentro de `SchemaV3.swift`, e os arquivos de `CashUp/Models` passaram a `extension SchemaV4`. O estágio V2 → V3 continua usando as classes da `SchemaV3`.
- **Nomes**: os campos novos são `ExpenseModel.amountInCents` e `SubcategoriaPlanejadaModel.valorPlanejadoCentavos` (`Int64`), e os `Double` antigos (`amount`, `valorPlanejado`) ficam no schema só para a conversão ler. Em todo o app, as propriedades de dinheiro passaram a `Int64` e ganharam o sufixo `InCents`/`Centavos` onde o nome antigo ficaria ambíguo (`DisplayableExpense.amountInCents`, `ExpenseEdit.amountInCents`, `AddTransactionViewModel.amountInCents`, `RecommendedPlanningItem.valorSugeridoCentavos`, `RecommendedPlanningViewModel.rendaInformadaCentavos`/`rendaDetectadaCentavos`). `BRLCurrencyFormatter.string(from: Double)` foi removido e substituído por `string(fromCentavos:)`: um literal inteiro como `680` agora seria lido como centavos, então a troca de nome força a revisão de cada chamada (as telas do onboarding foram convertidas para centavos).
- **Falha no `didMigrate` (seção 6)**: confirmado por teste que, quando o `didMigrate` lança, o SwiftData **já aplicou** a mudança estrutural: o `ModelContainer` lança erro, mas o store em disco passa a ser V4 com os centavos zerados, e a próxima abertura não repete o estágio. Sem tratamento, o usuário veria todos os totais zerados. Mitigação (decisão conservadora para os dados): a conversão virou uma função idempotente (`CashUpMigrationPlan.converterValoresPendentesParaCentavos`) que converte todo registro com valor no `Double` legado e **zera o legado** logo em seguida (o legado zerado é a marca de "já convertido"). Ela roda no `didMigrate` e também em toda abertura do container (`CashUpPersistence.makeContainer`); se falhar, o container não abre e o app mostra o aviso atual. Edições feitas na V4 nunca tocam o legado, então um valor editado para zero não é ressuscitado. **Na E0.4**: o estágio V4 → V5 deve chamar essa função no `willMigrate` (classes da V4, congeladas) antes de remover os campos, e o reparo sai do `makeContainer`.
- **Arredondamento**: `Centavos.de(reais:)` parte da representação decimal mais curta do `Double` (`19.9`, não `19.899999999999999`), converte em `Decimal` e arredonda meio para longe do zero (`NSDecimalRound(.plain)`); nunca `Int64(valor * 100)`, que truncaria `0,29` para 28. Não finitos viram 0 e o valor é limitado a 2^53 centavos (limite de precisão do `Double` legado). Tradeoff: `1.005` vira 101 e `2.675` vira 268 (o que o usuário "pretendia"); o app só gravava duas casas, então não há impacto prático.
- **Lógica de valor preservada**: o planejamento recomendado continua arredondando para múltiplos de R$ 5,00, agora **uma única vez**, a partir do valor exato em `Decimal` (`Centavos.arredondar(_ exato: Decimal, multiploDe: 500)`); passar por `fracao`/`dividir`/`proporcao` (que arredondam ao centavo) antes do múltiplo arredondava duas vezes e subia R$ 5 quando o exato ficava meio centavo abaixo do ponto médio (25% de R$ 1.009,99). Os totais 50/30/20 continuam em `Centavos.fracao`, e o último item de cada grupo absorve a sobra, como antes. As tolerâncias de ponto flutuante (`0.001`, `0.01`) saíram; os testes comparam centavos exatos. Limiares de insights: R$ 25/dia → 2.500; pico ≥ R$ 80 → 8.000; fim de semana ≥ R$ 100 → 10.000. A comparação "pico ≥ 2,5 × média" é feita sem divisão (`valor * 2 * quantidade >= total * 5`).
- **`Double` restante**: só razões/percentuais adimensionais (progresso, percentuais 50/30/20, `Centavos.razao`), o burn-rate do `SmartFinancialCoachEngine` e a fronteira com Swift Charts/`ProgressView` (`Centavos.double(de:)`). Views passam os valores por `BRLCurrencyFormatter.string(fromCentavos:)` (ou `Centavos.reais(de:)` se usarem `FormatStyle`): o `Int64` direto seria lido como reais (bug 100x achado no review do PR #42 na aba Planejamento, corrigido e coberto por `testFormatadorTrataOInteiroComoCentavosEAcompanhaOIdioma`; o card de Planejamento e o gráfico diário foram depois alinhados ao formatador único do app).
- **Fallback em memória**: quando o container persistente falha e o app cai para a memória, `RootView` não roda seed nem deduplicação e a versão do seed não é gravada (`PreparacaoDeDadosIniciais`); o aviso não manda mais reinstalar (reinstalar apagaria o store que poderia ser reparado).
- **Testes**: `CentavosUnitTests` (conversões, arredondamento, 0,10 + 0,20 = 30 centavos, formatação), e em `MigracaoUnitTests`: `testMigracaoCentavosExatos`, total do mês da fixture V3 idêntico antes/depois, arredondamento de cada valor, `testFalhaNoDidMigrateNaoCorrompeStore` (plano de migração só de teste cujo estágio V3 → V4 lança), idempotência da conversão e valor editado para zero não ressuscita. A falha é injetada por um `SchemaMigrationPlan` definido no alvo de testes, sem gancho no código de produção.
- **Validação manual pendente**: instalar o build do `main` (V1), registrar dados, instalar a branch por cima e conferir que os totais da Home **e da aba Planejamento** (card "Despesas Planejadas" e resumo por categoria) não mudam. Medir também a primeira abertura com 5 mil transações (risco da seção 6, ainda não medido).

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

#### E0.4 — notas de implementação

- **V4 congelada**: as classes da V4 foram copiadas (só atributos armazenados e relacionamentos, com `amount` e `valorPlanejado` `Double`) para dentro de `SchemaV4.swift`, e os arquivos de `CashUp/Models` passaram a `extension SchemaV5`, como na V3 → V4. `ContaModel` ficou em `CashUp/Models/ContaModel.swift` (não em `SchemaV5.swift`, que tem só o `enum SchemaV5`, `TipoLancamento` e `TipoConta`), para seguir o padrão dos outros modelos.
- **Estágio V4 → V5**: o `willMigrate` chama `CashUpMigrationPlan.converterValoresPendentesParaCentavos` (classes V4) e salva, antes de os `Double` sumirem. Isso também conserta um store que ficou V4 com centavos zerados por uma falha no `didMigrate` da E0.3. O reparo saiu de `CashUpPersistence.makeContainer`. O `didMigrate` cria a Carteira (ID fixo `SeedIDs.idContaCarteira`, para o iCloud reconhecer a mesma conta), liga as transações a ela e define o tipo a partir de `isIncome`.
- **Falha no `didMigrate` (seção 6)**: confirmado por teste que, como na E0.3, o SwiftData já aplicou a mudança estrutural quando o estágio lança: o store é V5 com **todas as transações sem conta e com `tipoRaw` no padrão (despesa)**, ou seja, as receitas somariam como despesa. Mitigação: `vincularTransacoesPendentesAContaPadrao` é idempotente (só toca transação sem conta; cria a Carteira só se achar alguma; não converte uma transferência) e roda no `didMigrate` e em toda abertura do container. Falha no `willMigrate` é limpa: o store continua V4 e a abertura seguinte migra normalmente. Ambos têm teste (planos de migração só de teste que lançam). Quando existir a V6, o reparo sai de `makeContainer` e passa ao `willMigrate` do estágio V5 → V6.
- **`isIncome` e `tipo`**: o plano não removia `isIncome`, e o app todo o lê, então ele ficou. `tipoRaw` (texto) é gravado junto, e `tipo` é a propriedade computada. O `init` deriva o tipo de `isIncome` quando `tipo` não é informado; edições devem usar `aplicarIsIncome(_:)`, que mantém os dois campos coerentes e não converte uma transferência. Se `tipoRaw` for ilegível, `tipo` cai para `isIncome`.
- **RN-14**: `DisplayableExpense` ganhou `tipo`. `ExpensesViewModel.expenses/incomes/transactions(on:isIncome:)`, as listas por aba, `HomeViewModel`, `SmartFinancialCoachEngine`, `TipsViewModel` (50/30/20) e `RecommendedPlanningViewModel.detectarRenda` passaram a filtrar por `tipo` (`.despesa`/`.receita`), então a transferência fica fora de todo total, gráfico e insight. Como exibir transferências nas listas é decisão da E2.
- **Conta padrão**: `ContaRepositoryProtocol.contaPadrao()` devolve a Carteira por ID; se ela não existir, a primeira conta por `ordem` (depois `criadoEm` e `instanciaID`); se não houver conta alguma (instalação nova), cria a Carteira sem salvar, e o `save()` do lançamento a persiste junto. `ExpensesViewModel.addExpense` liga a conta padrão quando o lançamento não traz conta; `ExpensesViewModel.init` passou a receber `contaRepository` (obrigatório). Editar uma ocorrência isolada ou "esta e as próximas" cria a nova transação (`ExpensesViewModel.transacaoDerivada`) com a conta da série, ou a conta padrão se a série não tiver conta, e herda o `tipo` (uma transferência continua transferência) e a `contaDestino`.
- **`ContaModel` enxuto**: `nome`, `tipoRaw`, `saldoInicialCentavos`, `ordem`, as inversas (`transacoes`, `transferenciasRecebidas`) e os campos de suporte do iCloud. Os campos de cartão (`limite`, `diaFechamento`, `diaVencimento`) entram na sub-fase do cartão, com uma migração leve, porque são todos opcionais/com default.
- **Fora desta sub-etapa**: deduplicação de contas por `id` no `DeduplicacaoService`. Dois aparelhos que migrarem criam duas "Carteira" com o mesmo `id`; o serviço precisa juntá-las (sobrevivente por `(criadoEm, instanciaID)`, reapontando `transacoes` e `transferenciasRecebidas`) antes de o iCloud ser ligado (F1, na Fase 2 do roadmap; a deduplicação de contas é pré-requisito dele). Também fica para a E2 a política de apagar uma conta com transações (hoje `.nullify`; a abertura do container religaria as órfãs à Carteira).
- **Testes**: `ContaRepositoryUnitTests` (10), `InMemoryContaRepository`, e em `MigracaoUnitTests`: Carteira criada e todas as transações ligadas, tipo a partir de `isIncome`, Carteira criada mesmo sem transações, totais da Home idênticos antes/depois, conversão pendente no `willMigrate`, falha no `didMigrate` e no `willMigrate` da V5, idempotência e transferência preservada. `ExpensesViewModelInMemoryTests` cobre conta padrão, herança de conta e de tipo/destino na edição de série (transferência e série sem conta, nos dois escopos), tipo coerente e transferência fora dos totais; há testes de transferência para `HomeViewModel` (restante planejado e insight), `SmartFinancialCoachEngine`, `TipsViewModel` (50/30/20) e `RecommendedPlanningViewModel.detectarRenda`; `HomeViewModelTests.testTransferenciaForaDosTotais` cobre a RN-14.
- **Validação manual (feita)**: o build do `main` (V1) com dados, a branch instalada por cima: os totais da Home não mudaram, existe a conta "Carteira" e um lançamento novo continua somando.
- **Reparo só com campos armazenados**: `vincularTransacoesPendentesAContaPadrao`/`garantirCarteira` usam `tipoRaw`, `isIncome` e constantes literais (nome da Carteira, valores de `tipoRaw`), sem as extensões do modelo vivo (`tipo`, `ContaModel.nomeCarteira`), para continuarem compilando quando a V5 virar cópia congelada (estágio V5 → V6).
- **Pendente para a E2 (conta padrão)**: hoje há duas regras. `contaPadrao()` usa a Carteira, senão a primeira conta por `ordem`; o reparo de abertura sempre recria a Carteira. Quando existir "apagar conta" (E2), uma Carteira apagada ressuscita na abertura e recebe as transações órfãs. A regra única (e se a Carteira pode ser apagada) é decisão da E2; documentada na RN-03.

### E0.5 — Store no App Group

**Criar**
- Entitlement `com.apple.security.application-groups` com `group.<bundle-id>`
- `CashUp/Services/Persistencia/StoreLocationMigrator.swift` — se o store antigo existe e o do grupo não, copia `default.store`, `-wal` e `-shm` para o container do grupo **antes** de abrir o `ModelContainer`. O arquivo antigo só é apagado depois de o container novo abrir com sucesso.

**Modificar**
- `CashUpApp.makeContainer` — `ModelConfiguration(groupContainer: .identifier(...))`

**Pronto quando**: o upgrade com o store no local antigo preserva os dados, e reabrir o app não copia o store de novo.

#### E0.5 — notas de implementação

- **Entitlement**: `CashUp/CashUp.entitlements` com `com.apple.security.application-groups` = `group.br.com.gustavosouto.cashup`, referenciado por `CODE_SIGN_ENTITLEMENTS` nas configurações Debug e Release do alvo CashUp. A pasta `CashUp/` é sincronizada (Xcode 16); o build confirma que o `.entitlements` não entra como recurso duplicado.
- **Localização injetável**: `StoreLocalizacao(antigo:, grupo:)`. `CashUpPersistence.localizacaoPadrao()` usa `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` para saber se o grupo existe e `ModelConfiguration(groupContainer: .identifier(...)).url` para o caminho (o mesmo que um widget usará). **Achado**: com o entitlement de App Group, o `ModelConfiguration(schema:)` padrão do SwiftData já aponta para o container do grupo (confirmado no simulador: `.url` padrão == `.url` do grupo). Por isso o store antigo é montado à mão (`URL.applicationSupportDirectory/default.store`); derivá-lo do `ModelConfiguration` padrão faria origem e destino coincidirem e a migração nunca copiaria nada. O container é aberto com `ModelConfiguration(schema:, url:)` nesse caminho, em vez de `groupContainer:` direto, para a cópia e a abertura usarem exatamente o mesmo arquivo e para os testes poderem apontar para diretórios temporários.
- **Fallback sem grupo**: se o container do grupo não está disponível (sem entitlement/assinatura), o app abre o store no local antigo e não move nada; nenhum dado é perdido. Se a cópia falhar, o app também abre no local antigo e tenta de novo na abertura seguinte. **Exceção (sentinela)**: depois da primeira abertura bem-sucedida no grupo, o app grava `Application Support/default.store.no-app-group` (no container do app, fora do grupo). Com a sentinela presente e o grupo indisponível (build sem o entitlement, troca de branch no aparelho), `makeContainer(localizacao:)` lança `StoreLocalizacaoErro.grupoIndisponivel` em vez de criar um store vazio no local antigo; o `CashUpApp` cai no fallback em memória e avisa. Sem a sentinela (aparelho que nunca usou o grupo) o comportamento é o de antes.
- **Cópia à prova de interrupção**: `StoreLocationMigrator.prepararGrupo()` copia `default.store`, `-wal`, `-shm` e o diretório de dados externos do Core Data (`.default_SUPPORT`, onde ficam os valores `.externalStorage` grandes, como `ExpenseModel.repetition`) para uma pasta temporária (`.migracao-<uuid>`) ao lado do destino, move os auxiliares (o destino de cada um deriva do nome do arquivo do grupo), grava um marcador `default.store.migracao-pendente` e move o `.store` por último. A existência do `.store` no grupo é o ponto de commit: nunca existe um `.store` de grupo incompleto. Resíduos de uma tentativa interrompida (pasta temporária, `-wal`/`-shm` soltos, marcador) são descartados no início da tentativa seguinte. Como o store antigo não está aberto nesse momento (a cópia roda antes do `ModelContainer`), copiar os três arquivos é um snapshot consistente do WAL; não foi usado checkpoint.
- **Apagar o antigo**: os marcadores separam dois estados: `.migracao-pendente` = "copiado e nunca aberto" e `.migracao-limpeza` = "aberto, falta limpar". `concluirMigracao()` só apaga o store antigo (e os auxiliares) se um marcador existir, isto é, se a cópia foi feita por este fluxo, e só depois de o container do grupo abrir: primeiro renomeia o pendente para limpeza, depois apaga (`.store` por último). A limpeza é retomável a partir de `.migracao-limpeza` e o marcador só sai quando não sobra nenhum arquivo do antigo. **O antigo nunca é apagado se o `.store` ou o `-wal` dele forem mais novos que o marcador** (gravações feitas depois da cópia, por exemplo por um build sem o grupo): registra `.fault`, tira o marcador e deixa o antigo intacto. Um store que apareça no local antigo com o grupo já existente (sem marcador) nunca é copiado nem apagado, e `prepararGrupo()` registra um erro nesse caso. A pasta `.migracao-<uuid>` vazia que sobre de um encerramento após o commit também é limpa no ramo "grupo já existia".
- **Falha na abertura do novo**: o erro sobe como antes (`CashUpApp` cai no fallback em memória e avisa o usuário) e o antigo fica intacto. Se havia marcador pendente (cópia nunca aberta) e o antigo existe, `descartarCopiaNaoAberta()` apaga do grupo o `.store` (primeiro), `-wal`, `-shm`, o diretório de dados externos e o marcador: um `didMigrate` que falha no meio deixa a cópia meio migrada, e o SwiftData não repete o estágio; reabri-la e depois apagar o único original intacto seria perder a rede de segurança. A próxima abertura recopia do original. Limite conhecido: um encerramento exatamente entre abrir o grupo e renomear o marcador seguido de uma falha de abertura descartaria uma cópia já aberta; a janela é de microssegundos, antes de qualquer gravação do app.
- **Testes** (`StoreLocationMigratorUnitTests`, 24 testes; `FixtureStoreV1` é compartilhada com `MigracaoUnitTests`): store na versão atual vai para o grupo, migrador copia os auxiliares e só apaga o antigo ao concluir (arquivos sintéticos), reabrir não copia, grupo e antigo existentes sem sobrescrever, instalação limpa, sem grupo, cópia interrompida na cópia e no move, resíduos (WAL válido velho, dados externos, marcador, pasta temporária) descartados com a cópia confirmada nesta tentativa, falha na cópia abre o antigo e tenta de novo, falha na abertura mantém o antigo e descarta a cópia (a segunda chamada devolve `.copiado`), encerrado após copiar e nunca aberto, retomada a partir de `.migracao-limpeza`, falha ao apagar mantém o marcador, antigo alterado depois da cópia (`.store` e `-wal`) não é apagado, grupo indisponível depois de migrar não cria store vazio, sentinela, diretório de dados externos copiado/movido antes do `.store`/apagado, destino derivado do nome do grupo, pasta temporária vazia no ramo "grupo já existia", **upgrade a partir da fixture V1 no caminho antigo** (totais, recorrência, planejamento, Carteira e remoção do antigo) e `testLocalizacaoPadraoDoGrupoCoincideComGroupContainer` (pulado se o grupo não estiver disponível).
- **Pendente**: o App Group precisa existir no Apple Developer (Signing & Capabilities com assinatura automática o cria) para build em aparelho: confirmar que `group.br.com.gustavosouto.cashup` está registrado no time e habilitado no App ID `br.com.gustavosouto.cashup` e regenerar o perfil de distribuição antes de publicar. Validação manual abaixo.

#### E0.5 — validação manual

O usuário **já validou o upgrade no simulador** (build 1.5 com dados, branch por cima: dados preservados). O que o simulador não prova é o comportamento em aparelho real com o App Group do portal, então o roteiro abaixo vale também para o aparelho antes de publicar.

**Upgrade (com dados)**
1. Instalar o build do `main` (1.5) e registrar dados: despesas, uma série recorrente com uma ocorrência excluída, planejamento do mês e uma receita.
2. Instalar a branch por cima, sem apagar o app.
3. Abrir e conferir os totais da Home e da aba Planejamento, a série recorrente (com a ocorrência excluída), o planejamento e a conta "Carteira".
4. Conferir que o store antigo sumiu do container do app e que existe `default.store` no container do grupo (Xcode, Devices and Simulators, Download Container).
5. Fechar e abrir de novo: os dados continuam, nada é copiado de novo e um lançamento novo soma.

**Instalação limpa**
1. Apagar o app e instalar a branch.
2. Abrir: as categorias padrão aparecem, um lançamento novo é salvo e reabrir mantém os dados.
3. Conferir que o store nasceu no grupo (não existe `default.store` no `Application Support` do app) e que existe `default.store.no-app-group` no `Application Support`.

**Grupo indisponível depois de migrar** (aparelho de desenvolvimento): com o store já no grupo, instalar um build sem o entitlement. Esperado: o aviso "Não foi possível abrir seus dados" e nenhum store vazio criado em `Application Support`.

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
| `testUpgradeDoStoreDaVersao15NoLocalAntigoMigraOSchemaEMudaDeLocal` | E0.5: fixture V1 no local antigo, aberta pelo fluxo do grupo: totais preservados e antigo removido |

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
