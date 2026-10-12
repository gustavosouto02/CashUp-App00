# 📋 Regras de Negócio — CashUp

**Documento**: Regras de Negócio e Invariantes do Domínio  
**Fonte da Verdade**: Código-fonte inspecionado (`CashUp/Models`, `CashUp/Views`), testes unitários e especificação funcional.  
**Moeda Padrão**: Real Brasileiro (BRL / R$), Locale `pt_BR`.  

---

## Índice das Regras de Negócio

1. [Transações e Lançamentos (RN-01 a RN-05, RN-19)](#1-transações-e-lançamentos)
2. [Categorias, Subcategorias e Favoritos (RN-06 a RN-08)](#2-categorias-subcategorias-e-favoritos)
3. [Planejamento Orçamentário Mensal (RN-09 a RN-13)](#3-planejamento-orçamentário-mensal)
4. [Dashboard, Métricas e Gráficos (RN-14 a RN-15)](#4-dashboard-métricas-e-gráficos)
5. [Navegação Temporal Sincronizada (RN-16)](#5-navegação-temporal-sincronizada)
6. [Segurança, Onboarding e Dicas (RN-17 a RN-18)](#6-segurança-onboarding-e-dicas)

---

## 1. Transações e Lançamentos

### RN-01 — Validação de Valor Monetário
- **Regra**: O valor (`amount`) de uma transação deve ser **estritamente maior que zero** (`amount > 0.0`).
- **Validação**: Tentativas de salvar transações com valor `0.0` ou negativo são rejeitadas na camada de validação do ViewModel (`AddTransactionViewModel.criarTransacaoEChamarClosure`) antes de qualquer chamada de inserção no contexto do banco.
- **Armazenamento**: Valores são armazenados como ponto flutuante de precisão dupla (`Double`) no `ExpenseModel`.
- **Formatação**: Exibição obrigatória com duas casas decimais no padrão brasileiro (`R$ 1.250,50`) via `NumberFormatter` com locale `pt_BR`.

### RN-02 — Classificação Semântica (Despesa vs. Receita)
- **Regra**: Toda transação é classificada como **Despesa** (`isIncome: false`) ou **Receita** (`isIncome: true`).
- **Comportamento Especial da Categoria "Renda"**:
  - A categoria com ID fixo `SeedIDs.idRenda` é a categoria oficial do sistema para entradas financeiras.
  - Qualquer transação vinculada à categoria "Renda" é **forçada automaticamente** como receita (`isIncome = true`), mesmo que o controle na tela estivesse inicialmente em despesa.
- **Filtro de Seleção na Interface**:
  - Ao cadastrar uma **Despesa**: A categoria "Renda" é omitida da listagem de opções.
  - Ao cadastrar uma **Receita**: Apenas a categoria "Renda" e suas respectivas subcategorias são disponibilizadas para seleção.

### RN-03 — Obrigatoriedade de Associação Taxonômica
- **Regra**: Nenhuma transação pode ser salva sem estar expressamente vinculada a uma `CategoriaModel` **e** a uma `SubcategoriaModel`.
- **Campos Opcionais**: O campo `expenseDescription` (descrição textual da transação) é opcional; se deixado em branco, a transação adota visualmente o nome da própria subcategoria selecionada.

### RN-04 — Recorrência e Projeção Virtual
- **Regra**: Uma transação pode ser configurada como recorrente via `RepetitionData`.
- **Frequências Suportadas**:
  | Opção (`RepeatOption`) | Intervalo de Repetição |
  |---|---|
  | `.nunca` | Pontual (sem repetição) |
  | `.diariamente` | Repete a cada 1 dia |
  | `.semanalmente` | Repete a cada 7 dias (semanal) |
  | `.aCada10Dias` | Repete a cada 10 dias |
  | `.mensalmente` | Repete no mesmo dia a cada 1 mês |
  | `.anualmente` | Repete na mesma data a cada 1 ano |
- **Projeção em Memória (Sem Poluição de Banco)**:
  - O sistema **NÃO cria registros físicos repetidos** no banco de dados para cada ocorrência futura.
  - Apenas o registro mestre `ExpenseModel` é persistido.
  - A função `ExpenseModel.generateOccurrences(forDateInterval:calendar:)` calcula as ocorrências virtuais sob demanda (`[DisplayableExpense]`) para o mês que está sendo visualizado na tela.
- **Data Final (`endDate`)**:
  - O campo `endDate` é opcional.
  - Se o usuário não estipular data final ao ativar a recorrência, o aplicativo adota como padrão sugerido o período de **1 ano a partir da data inicial**.

### RN-05 — Protocolo de Exclusão de Ocorrências Recorrentes
Ao solicitar a exclusão de uma ocorrência que pertença a uma série recorrente (`DisplayableExpense.isRecurringInstance == true`), o usuário deve escolher um dos três escopos de exclusão:

```
                  ┌─────────────────────────────────────────┐
                  │    Exclusão de Transação Recorrente     │
                  └─────────────────────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
        ▼                              ▼                              ▼
 [ Apenas Esta ]             [ Esta e Futuras ]               [ Toda a Série ]
        │                              │                              │
Adiciona a data em            Atualiza endDate da           Executa modelContext.delete
repetition.excludedDates      série para (data - 1 dia).    no ExpenseModel mestre
(ocorrência pontual           Se data <= data início,       (remove histórico e futuro)
é ocultada do cálculo)        remove série toda (fallback).
```

- **Scope 1 — Apenas Esta Ocorrência (`.thisOccurrenceOnly`)**:
  - A data exata da ocorrência (normalizada para início do dia via `calendar.startOfDay`) é adicionada à lista `repetitionData.excludedDates`.
  - As demais ocorrências passadas e futuras permanecem intactas.
- **Scope 2 — Esta e Todas as Futuras (`.thisAndAllFutureOccurrences`)**:
  - O campo `repetitionData.endDate` é atualizado para o dia imediatamente anterior à data da ocorrência selecionada.
  - *Regra de Salvaguarda (Fallback)*: Caso a nova data final calculada seja anterior ou igual à data de início da série mestre, o sistema deleta o registro mestre por completo.
- **Scope 3 — Toda a Série (`.entireSeries`)**:
  - O `ExpenseModel` original é excluído do banco de dados via `modelContext.delete`, eliminando todo o histórico e ocorrências futuras.

### RN-19 — Limite Temporal de Lançamentos
- **Regra**: Transações não podem ser registradas com data superior a **100 anos no futuro** a partir da data atual.
- **Tratamento**: A tentativa de inserção dispara erro de validação com mensagem descritiva: *"A data da despesa não pode ser superior a 100 anos no futuro"*.

---

## 2. Categorias, Subcategorias e Favoritos

### RN-06 — Seed Determinístico e Idempotência
- **Regra**: Na primeira inicialização do app (quando a tabela de categorias estiver vazia), o sistema popula automaticamente **7 categorias padrão** e suas respectivas subcategorias.
- **Identificadores Fixos (`SeedIDs`)**:
  - As categorias do seed utilizam UUIDs constantes e determinísticos para garantir integridade referencial e facilitar regras de sistema (como o isolamento da categoria "Renda"):
    - `idRenda`: `A0A0A0A0-A0A0-A0A0-A0A0-A0A0A0A0A0A0`
    - `idEntretenimento`: `B1B1B1B1-B1B1-B1B1-B1B1-B1B1B1B1B1B1`
    - `idDiversos`: `C2C2C2C2-C2C2-C2C2-C2C2-C2C2C2C2C2C2`
    - `idComidasEBebidas`: `D3D3D3D3-D3D3-D3D3-D3D3-D3D3D3D3D3D3`
    - `idHabitacao`: `E4E4E4E4-E4E4-E4E4-E4E4-E4E4E4E4E4E4`
    - `idTransporte`: `F5F5F5F5-F5F5-F5F5-F5F5-F5F5F5F5F5F5`
    - `idEstiloDeVida`: `A6A6A6A6-A6A6-A6A6-A6A6-A6A6A6A6A6A6`
- **Idempotência**: A função `popularDadosIniciaisSeNecessario` verifica a existência prévia dos IDs no contexto antes de executar qualquer inserção, impedindo duplicação de dados.

### RN-07 — Algoritmo de Favoritos por Frequência de Uso
- **Regra**: O sistema mantém um contador cumulativo de utilizações (`usageCount: Int`) em cada `SubcategoriaModel`.
- **Incremento**: A cada transação criada com sucesso, o método `CategoriesViewModel.registrarUso` incrementa `subcategoria.usageCount += 1`.
- **Seleção dos Favoritos**:
  - São selecionadas as **até 6 subcategorias** com maior `usageCount` (`usageCount > 0`).
  - O cálculo é estritamente filtrado pelo tipo de operação ativa: subcategorias de "Renda" só aparecem no atalho quando a tela estiver em modo Receita; subcategorias de outras categorias só aparecem quando em modo Despesa.

### RN-08 — Proteção de Categorias Padrão
- **Regra**: As categorias pré-configuradas do seed não podem ser excluídas pelo usuário para evitar quebra de integridade referencial nas regras de sistema.
- **Customização**: O usuário poderá criar e editar subcategorias personalizadas associadas às categorias existentes (funcionalidade estruturada em `CategoriesViewEdit`).

---

## 3. Planejamento Orçamentário Mensal

### RN-09 — Indexação Temporal do Orçamento
- **Regra**: O planejamento orçamentário é estritamente mensal e anual.
- **Normalização da Data**: Toda instância de `CategoriaPlanejadaModel` normaliza seu campo `mesAno` obrigatoriamente para as `00:00:00` do **primeiro dia do mês correspondente** (`Date().startOfMonth()`).
- **Unicidade de Categoria no Mês**: Uma dada `CategoriaModel` só pode ser associada a **uma única** `CategoriaPlanejadaModel` em um mesmo mês. Se o usuário tentar planejar uma categoria que já consta no mês, o fluxo é automaticamente redirecionado para inclusão de subcategorias no registro já existente.

### RN-10 — Estrutura Hierárquica e Somatório
- **Regra**: O orçamento é composto em dois níveis: **Categoria Planejada → Subcategorias Planejadas**.
- **Unicidade de Subcategoria**: Uma mesma subcategoria não pode ser duplicada dentro do planejamento da mesma categoria no mesmo mês.
- **Valor da Categoria**: O valor orçado total de uma categoria é calculado dinamicamente:
  $$\text{ValorTotalPlanejado}(\text{Categoria}) = \sum \text{valorPlanejado}(\text{Subcategoria}_i)$$
- **Validação de Valor**: Todo `valorPlanejado` deve ser $\ge 0.0$.

### RN-11 — Deleção em Cascata e Limpeza Automática
- **Cascade Delete**: Se uma `CategoriaPlanejadaModel` for deletada, todas as suas `SubcategoriaPlanejadaModel` associadas são deletadas automaticamente pelo SwiftData (`deleteRule: .cascade`).
- **Limpeza de Categoria Vazia**: Caso o usuário remova individualmente todas as subcategorias de uma categoria planejada, a `CategoriaPlanejadaModel` correspondente é **deletada automaticamente** do banco de dados, evitando categorias órfãs com valor zero na interface.

### RN-12 — Cópia Inteligente de Orçamento entre Meses
- **Regra**: O usuário pode duplicar o orçamento configurado no mês atual diretamente para o mês subsequente ($Mês + 1$).
- **Tratamento de Conflitos**:
  - Categorias que **já existirem** no planejamento do mês de destino **são ignoradas** (não sobrescreve nem altera os valores pré-existentes do próximo mês).
  - Apenas categorias e subcategorias ausentes no mês de destino são copiadas, com seus respectivos valores originais mantidos integralmente.
- **Bloqueio de Operação Vazia**: Se o mês atual não possuir nenhuma categoria planejada, a ação é bloqueada e um alerta informativo é apresentado na UI.

### RN-13 — Zeramento de Planejamento Mensal
- **Regra**: O usuário tem a opção de "Zerar Planejamento" do mês corrente.
- **Ação**: Deleta em lote todos os registros de `CategoriaPlanejadaModel` associados ao mês visualizado, limpando a base do período sem afetar o histórico de despesas reais registradas.

---

## 4. Dashboard, Métricas e Gráficos

### RN-14 — Fórmulas de Consolidação Financeira Mensal
No painel principal (`HomeViewModel`), as métricas do mês selecionado são apuradas rigorosamente pelas fórmulas abaixo:

| Métrica | Identificador | Fórmula / Regra |
|---|---|---|
| **Total Gasto** | `totalSpentMonth` | $\sum \text{amount}$ de todas as despesas (pontuais + ocorrências virtuais) do mês |
| **Total de Receitas** | `totalIncomeMonth` | $\sum \text{amount}$ de todas as receitas do mês |
| **Total Planejado** | `totalPlanejadoMes` | $\sum \text{valorPlanejado}$ de todas as subcategorias orçadas no mês |
| **Gasto em Planejadas** | `gastoEmPlanejadas` | $\sum \text{amount}$ das despesas cuja categoria **possui orçamento no mês** |
| **Saldo Restante** | `totalRestantePlanejadoMes` | $\text{Total Planejado} - \text{Gasto em Planejadas}$ |
| **Progresso da Categoria** | `progressoPlanejado` | $\min\left(\frac{\text{Total Gasto na Categoria}}{\text{Valor Planejado da Categoria}}, 1.0\right)$ (limitado a 100%) |

> [!IMPORTANT]
> **Regra de Ouro do Saldo Restante**: Gastos efetuados em categorias que **NÃO foram planejadas** no mês não subtraem do Saldo Restante do Planejamento. O Saldo Restante reflete unicamente a aderência ao orçamento prévio estipulado pelo usuário.

### RN-15 — Gráfico Diário de Ritmo de Despesas
- **Regra**: O componente `InteractiveDailyExpensesChart` plota um gráfico diário abrangendo todos os dias do mês selecionado (do dia 1 ao último dia do mês).
- **Densidade Contínua**: Dias sem nenhuma transação mantêm uma barra/ponto com valor `0.0`, preservando a escala e a continuidade temporal.
- **Consolidação de Recorrências**: Transações recorrentes geram peso financeiro exatamente no dia correspondente à sua ocorrência virtual no calendário.

---

## 5. Navegação Temporal Sincronizada

### RN-16 — Sincronismo Global de Mês via Combine
- **Regra**: O mês de referência selecionado pelo usuário deve ser **idêntico** em todas as abas e telas do app (Home, Despesas e Planejamento).
- **Mecanismo Reativo**:
  - Os ViewModels compartilham a propriedade `@Published var currentMonth: Date`.
  - A alteração do mês em qualquer aba dispara eventos via Combine (`removeDuplicates`, `RunLoop.main`), propagando a mudança e recalculando métricas, listas e gráficos instantaneamente.
- **Granularidade da Navegação**: A transição ocorre sempre em incrementos ou decrementos de **$\pm 1$ mês**, recalculando o novo primeiro dia do mês (`startOfMonth()`).

---

## 6. Segurança, Onboarding e Dicas

### RN-17 — Proteção Biométrica de Privacidade
- **Regra**: O acesso aos dados financeiros do aplicativo deve ser protegido por Face ID / Touch ID através do framework `LocalAuthentication`.
- **Comportamento**: Ao habilitar a biometria nas configurações, o app deve solicitar autenticação biométrica sempre que passar do estado inativo/background para o primeiro plano.

### RN-18 — Educação Financeira e Metodologia 50/30/20
- **Regra**: A seção de Dicas (`TipsView`) provê orientações baseadas na metodologia orçamentária consagrada 50/30/20:
  - **50% — Gastos Essenciais**: Habitação, alimentação básica, saúde, contas fixas.
  - **30% — Estilo de Vida**: Lazer, restaurantes, compras, bem-estar.
  - **20% — Poupança e Reserva**: Criação de reserva de emergência e quitação de dívidas.
- **Apresentação**: Interface visual amigável com cartões categorizados e dicas rápidas para evitar compras por impulso e otimizar assinaturas recorrentes.
