# CashUp — Documentação Oficial do Projeto 💸

Bem-vindo à documentação técnica e de produto do **CashUp**, aplicativo de gestão financeira pessoal para iOS desenvolvido em **SwiftUI** e **SwiftData**, concebido originalmente no ecossistema da **Apple Developer Academy** e publicado na **App Store**.

Esta documentação adota o mesmo rigor arquitetural, clareza e padrão de engenharia aplicado no ecossistema de APIs de alta performance (como o padrão utilizado no projeto `c18-api`), adaptado com maestria para a arquitetura mobile iOS nativa moderna.

---

## 🗺️ Mapa da Documentação

A pasta `docs/` está estruturada em duas frentes fundamentais: **Rules & Specifications** (diretrizes do sistema) e **Plans** (templates e planos executáveis de implementação).

```
docs/
├── README.md                           ← Este documento índice
├── rules/
│   ├── product_vision.md               ← Visão de produto, público-alvo, personas, propostas de valor e métricas
│   ├── business_rules.md               ← Regras de negócio canônicas (RN-01 a RN-18), fluxos e cálculos
│   ├── architecture.md                 ← Arquitetura Clean MVVM + Repository Protocols + SwiftData + Combine
│   ├── project_structure.md            ← Estrutura física de pastas, convenções de arquivos e Clean Code
│   └── gap_analysis_and_roadmap.md     ← Auditoria do código existente ("O que já tem"), débitos e roadmap
└── plans/
    ├── template_implementation_plan.md ← Template canônico para especificação e execução de novas features
    └── plano_correcao_lacunas.md       ← Plano ativo: 10 etapas priorizadas a partir do code review de 08/10/2026
```

---

## 📚 Sumário dos Documentos

### 1. [`rules/product_vision.md`](rules/product_vision.md) — Visão de Produto
- **Propósito**: Define o porquê do produto existir, suas dores resolvidas e o público-alvo (jovens universitários e adultos no início da vida financeira independente).
- **Conteúdo**: Pilares da experiência, proposta de valor, jornada do usuário, design mobile dark-first e North Star Metrics.

### 2. [`rules/business_rules.md`](rules/business_rules.md) — Regras de Negócio
- **Propósito**: Fonte da verdade (Source of Truth) de todas as regras de validação, limites, cálculos financeiros e comportamentos do domínio.
- **Conteúdo**: RN-01 a RN-18 detalhadas (recorrência virtual, categorização especial de renda, fórmulas do dashboard, cascade delete e cópia de orçamento mensal).

### 3. [`rules/architecture.md`](rules/architecture.md) — Arquitetura de Software
- **Propósito**: Padronização da arquitetura iOS, garantindo desacoplamento, testabilidade e separação de responsabilidades.
- **Conteúdo**: Clean MVVM com camada de Protocolos de Repositório (inspirado no padrão Layer-First do `c18-api`), isolamento do SwiftData, gerenciamento de estado no `@MainActor`, Combine para sincronização temporal reativa e testes com container em memória.

### 4. [`rules/project_structure.md`](rules/project_structure.md) — Estrutura do Projeto e Clean Code
- **Propósito**: Guia para localização de artefatos, criação de novos arquivos e convenções de código.
- **Conteúdo**: Árvore de diretórios, convenções de sufixos (`View`, `ViewModel`, `Model`, `Protocol`), regras de Clean Code (Zero comentários desnecessários, código autoexplicativo, tipos fortes).

### 5. [`rules/gap_analysis_and_roadmap.md`](rules/gap_analysis_and_roadmap.md) — Auditoria Atual & Roadmap
- **Propósito**: Diagnóstico especialista sobre o estado real do app ("O que já tem funcional") versus oportunidades e débitos técnicos.
- **Conteúdo**: Mapeamento de telas e componentes existentes, catálogo de lacunas (L-01 a L-10) com matriz de impacto/esforço e plano evolutivo em 4 fases.

### 6. [`plans/template_implementation_plan.md`](plans/template_implementation_plan.md) — Template de Plano de Implementação
- **Propósito**: Template canônico para planejar qualquer nova funcionalidade ou refatoração no CashUp antes de escrever o código.
- **Conteúdo**: Roteiro estruturado em 12 etapas, cobrindo Models, Protocolos, Repositórios, Services/ViewModels, Views SwiftUI, suíte de testes unitários isolados e testes de interface (XCUITest).

### 7. [`plans/plano_correcao_lacunas.md`](plans/plano_correcao_lacunas.md) — Plano de Correção de Lacunas (ativo)
- **Propósito**: Executar, em ordem de prioridade, as correções do code review de 08/10/2026: 3 bugs críticos de recorrência/persistência, 5 bugs médios, débitos técnicos e as 8 lacunas funcionais (biometria, onboarding, CRUD de categorias, edição de ocorrência única, dicas dinâmicas, camada de repositório).
- **Conteúdo**: 10 etapas dependency-ordered, cada uma com arquivos a criar/modificar/apagar, assinaturas de código, tabela de testes e bloco obrigatório de limpeza ao final.

---

## ⚙️ Diretrizes para Assistentes de IA e Desenvolvedores

1. **Consulte antes de codificar**: Qualquer implementação no CashUp deve estar embasada nas regras de [`docs/rules/business_rules.md`](rules/business_rules.md) e na arquitetura de [`docs/rules/architecture.md`](rules/architecture.md).
2. **Use o template de plano**: Para features médias ou grandes, elabore previamente o plano em `docs/plans/` utilizando o [`template_implementation_plan.md`](plans/template_implementation_plan.md).
3. **Clean Code rigoroso**: Não adicione comentários redundantes ou explicativos em arquivos de código Swift; o código deve ser autoexplicativo através de nomenclatura precisa e tipos estritos.
4. **Isolamento de Testes**: Todo repositório e viewModel deve ser passível de teste com `ModelConfiguration(isStoredInMemoryOnly: true)` sem depender de persistência em disco ou estado compartilhado.
