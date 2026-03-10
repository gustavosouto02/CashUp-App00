#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether, PageBreak
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.platypus import Flowable
import os

OUTPUT = os.path.join(os.path.dirname(__file__), "CashUp_Regras_de_Negocio.pdf")

# ── Paleta de cores ──────────────────────────────────────────────────────────
VERDE      = colors.HexColor("#2D6A4F")
VERDE_CLARO= colors.HexColor("#52B788")
CINZA_ESCURO = colors.HexColor("#2B2D42")
CINZA_MED  = colors.HexColor("#4A4E69")
CINZA_CLARO= colors.HexColor("#F0F1F3")
BRANCO     = colors.white
VERMELHO   = colors.HexColor("#D62828")
LARANJA    = colors.HexColor("#E07B39")
AZUL       = colors.HexColor("#2D6A9F")

# ── Estilos ──────────────────────────────────────────────────────────────────
base_styles = getSampleStyleSheet()

STYLES = {
    "cover_title": ParagraphStyle(
        "cover_title",
        fontName="Helvetica-Bold",
        fontSize=36,
        textColor=BRANCO,
        alignment=TA_CENTER,
        spaceAfter=8,
    ),
    "cover_sub": ParagraphStyle(
        "cover_sub",
        fontName="Helvetica",
        fontSize=14,
        textColor=colors.HexColor("#C8E6C9"),
        alignment=TA_CENTER,
        spaceAfter=4,
    ),
    "cover_meta": ParagraphStyle(
        "cover_meta",
        fontName="Helvetica",
        fontSize=10,
        textColor=colors.HexColor("#A5D6A7"),
        alignment=TA_CENTER,
    ),
    "section_title": ParagraphStyle(
        "section_title",
        fontName="Helvetica-Bold",
        fontSize=16,
        textColor=BRANCO,
        spaceBefore=14,
        spaceAfter=8,
        backColor=VERDE,
        borderPadding=(6, 10, 6, 10),
        leading=20,
    ),
    "rule_title": ParagraphStyle(
        "rule_title",
        fontName="Helvetica-Bold",
        fontSize=11,
        textColor=CINZA_ESCURO,
        spaceBefore=10,
        spaceAfter=4,
        backColor=CINZA_CLARO,
        borderPadding=(4, 8, 4, 8),
        leftIndent=0,
    ),
    "body": ParagraphStyle(
        "body",
        fontName="Helvetica",
        fontSize=9.5,
        textColor=CINZA_ESCURO,
        leading=14,
        spaceAfter=4,
    ),
    "bullet": ParagraphStyle(
        "bullet",
        fontName="Helvetica",
        fontSize=9.5,
        textColor=CINZA_ESCURO,
        leading=14,
        leftIndent=14,
        spaceAfter=2,
        bulletIndent=4,
    ),
    "table_header": ParagraphStyle(
        "table_header",
        fontName="Helvetica-Bold",
        fontSize=9,
        textColor=BRANCO,
        alignment=TA_CENTER,
    ),
    "table_cell": ParagraphStyle(
        "table_cell",
        fontName="Helvetica",
        fontSize=9,
        textColor=CINZA_ESCURO,
        leading=12,
    ),
    "table_cell_center": ParagraphStyle(
        "table_cell_center",
        fontName="Helvetica",
        fontSize=9,
        textColor=CINZA_ESCURO,
        alignment=TA_CENTER,
        leading=12,
    ),
    "tag_code": ParagraphStyle(
        "tag_code",
        fontName="Courier-Bold",
        fontSize=9,
        textColor=VERDE,
        backColor=colors.HexColor("#E8F5E9"),
        borderPadding=(2, 4, 2, 4),
    ),
    "footer": ParagraphStyle(
        "footer",
        fontName="Helvetica",
        fontSize=7.5,
        textColor=colors.HexColor("#9E9E9E"),
        alignment=TA_CENTER,
    ),
    "toc_title": ParagraphStyle(
        "toc_title",
        fontName="Helvetica-Bold",
        fontSize=13,
        textColor=VERDE,
        spaceBefore=4,
        spaceAfter=6,
    ),
    "toc_item": ParagraphStyle(
        "toc_item",
        fontName="Helvetica",
        fontSize=9.5,
        textColor=CINZA_ESCURO,
        leading=15,
    ),
    "gap_title": ParagraphStyle(
        "gap_title",
        fontName="Helvetica-Bold",
        fontSize=11,
        textColor=VERMELHO,
        spaceBefore=10,
        spaceAfter=4,
        backColor=colors.HexColor("#FFF3F3"),
        borderPadding=(4, 8, 4, 8),
    ),
}

# ── Helpers ──────────────────────────────────────────────────────────────────

def hr(color=VERDE_CLARO, width=0.5):
    return HRFlowable(width="100%", thickness=width, color=color, spaceAfter=6, spaceBefore=2)

def section(title):
    return [
        Spacer(1, 0.3*cm),
        Paragraph(f"  {title}", STYLES["section_title"]),
        Spacer(1, 0.15*cm),
    ]

def rule(code, title):
    return Paragraph(f"  {code} — {title}", STYLES["rule_title"])

def body(text):
    return Paragraph(text, STYLES["body"])

def bullet(text):
    return Paragraph(f"• {text}", STYLES["bullet"])

def spacer(h=0.2):
    return Spacer(1, h*cm)

def table(headers, rows, col_widths=None, row_color=True):
    page_w = A4[0] - 3*cm
    if col_widths is None:
        w = page_w / len(headers)
        col_widths = [w] * len(headers)

    header_row = [Paragraph(h, STYLES["table_header"]) for h in headers]
    data = [header_row]
    for i, row in enumerate(rows):
        data.append([Paragraph(str(c), STYLES["table_cell"]) for c in row])

    style = TableStyle([
        ("BACKGROUND", (0,0), (-1,0), VERDE),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [BRANCO, CINZA_CLARO] if row_color else [BRANCO]),
        ("GRID", (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("FONTNAME", (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTSIZE", (0,0), (-1,-1), 9),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ("LEFTPADDING", (0,0), (-1,-1), 7),
        ("RIGHTPADDING", (0,0), (-1,-1), 7),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
    ])
    return Table(data, colWidths=col_widths, style=style, repeatRows=1)

# ── Cover page ───────────────────────────────────────────────────────────────

class ColorRect(Flowable):
    def __init__(self, width, height, fill_color):
        super().__init__()
        self.width = width
        self.height = height
        self.fill_color = fill_color

    def draw(self):
        self.canv.setFillColor(self.fill_color)
        self.canv.rect(0, 0, self.width, self.height, stroke=0, fill=1)

def build_cover():
    pw, ph = A4
    cover = []
    # fundo verde escuro via grande rect
    cover.append(ColorRect(pw - 3*cm, 10*cm, VERDE))
    cover.append(Spacer(1, -10.4*cm))  # voltar para escrever sobre

    cover.append(Spacer(1, 2.5*cm))
    cover.append(Paragraph("CashUp", STYLES["cover_title"]))
    cover.append(Paragraph("Análise de Negócio &amp; Regras de Negócio", STYLES["cover_sub"]))
    cover.append(Spacer(1, 0.4*cm))
    cover.append(Paragraph("Sistema de Gestão Financeira Pessoal — iOS / SwiftUI", STYLES["cover_meta"]))
    cover.append(Spacer(1, 0.3*cm))
    cover.append(Paragraph("Documento gerado em 05/03/2026", STYLES["cover_meta"]))
    cover.append(Spacer(1, 2.2*cm))

    # caixa cinza com sumário executivo
    cover.append(HRFlowable(width="100%", thickness=1, color=VERDE_CLARO, spaceAfter=12))
    cover.append(Paragraph(
        "Este documento apresenta a análise completa do domínio de negócio do aplicativo "
        "<b>CashUp</b>, mapeando todas as entidades, fluxos e regras que governam o "
        "comportamento do sistema. Também identifica lacunas funcionais e oportunidades "
        "de melhoria levantadas pela inspeção do código-fonte.",
        STYLES["body"]
    ))
    cover.append(HRFlowable(width="100%", thickness=1, color=VERDE_CLARO, spaceBefore=12, spaceAfter=0))
    return cover

# ── Sumário ──────────────────────────────────────────────────────────────────

def build_toc():
    items = [
        ("1", "Visão Geral do Sistema"),
        ("2", "Domínio — Entidades Principais"),
        ("3", "Regras de Negócio — Transações"),
        ("4", "Regras de Negócio — Categorias"),
        ("5", "Regras de Negócio — Planejamento Orçamentário"),
        ("6", "Regras de Negócio — Dashboard e Métricas"),
        ("7", "Regras de Negócio — Navegação Temporal"),
        ("8", "Regras de Negócio — Segurança e Onboarding"),
        ("9", "Lacunas Identificadas (Gap Analysis)"),
    ]
    elems = []
    elems.append(PageBreak())
    elems += section("Sumário")
    elems.append(spacer(0.1))
    for num, title in items:
        elems.append(Paragraph(f"<b>{num}.</b>  {title}", STYLES["toc_item"]))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

# ── Conteúdo ─────────────────────────────────────────────────────────────────

def build_visao_geral():
    elems = []
    elems.append(PageBreak())
    elems += section("1. Visão Geral do Sistema")
    elems.append(body(
        "O <b>CashUp</b> é um aplicativo iOS de <b>gestão financeira pessoal</b> que permite ao usuário "
        "registrar receitas e despesas, organizá-las em categorias hierárquicas e planejar um orçamento "
        "mensal. Toda a persistência é <b>local</b>, utilizando <b>SwiftData</b> (sem sincronização remota). "
        "A moeda padrão é o <b>Real Brasileiro (BRL)</b>, com formatação pt_BR."
    ))
    elems.append(spacer(0.2))

    elems.append(body("<b>Arquitetura:</b> MVVM com SwiftUI + SwiftData. ViewModels são classes "
                      "ObservableObject anotadas com @MainActor. Combine é utilizado para sincronização "
                      "reativa entre ViewModels."))
    elems.append(spacer(0.2))

    elems.append(body("<b>Módulos funcionais identificados:</b>"))
    modulos = [
        ("Transações", "Registro de receitas e despesas, com suporte a recorrência"),
        ("Categorias", "Hierarquia Categoria → Subcategoria com seed de dados iniciais"),
        ("Planejamento", "Orçamento mensal por categoria/subcategoria"),
        ("Dashboard (Home)", "Resumo financeiro do mês com gráfico diário"),
        ("Dicas", "Previsto no código; não implementado"),
        ("Autenticação", "Biometria prevista; não implementada"),
        ("Onboarding", "Fluxo de boas-vindas previsto; não implementado"),
    ]
    elems.append(spacer(0.1))
    elems.append(table(
        ["Módulo", "Descrição"],
        modulos,
        col_widths=[5.5*cm, 12*cm]
    ))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_entidades():
    elems = []
    elems += section("2. Domínio — Entidades Principais")

    entidades = [
        ("ExpenseModel", "Transação (despesa ou receita)", "amount, date, isIncome, repetition, categoria, subcategoria"),
        ("CategoriaModel", "Agrupamento temático", "nome, icon, cor (RGB), subcategorias[]"),
        ("SubcategoriaModel", "Classificação específica", "nome, icon, usageCount, categoria"),
        ("CategoriaPlanejadaModel", "Orçamento de categoria por mês", "mesAno, categoriaOriginal, subcategoriasPlanejadas[]"),
        ("SubcategoriaPlanejadaModel", "Valor orçado por subcategoria", "valorPlanejado, subcategoriaOriginal, categoriaPlanejada"),
        ("RepetitionData", "Dados de recorrência de transação", "repeatOption, endDate?, excludedDates[]?"),
    ]
    elems.append(table(
        ["Entidade", "Responsabilidade", "Atributos Principais"],
        entidades,
        col_widths=[5.5*cm, 5.5*cm, 7*cm]
    ))
    elems.append(spacer(0.2))

    elems.append(body("<b>Relacionamentos:</b>"))
    elems.append(bullet("ExpenseModel → CategoriaModel (opcional, N:1)"))
    elems.append(bullet("ExpenseModel → SubcategoriaModel (opcional, N:1)"))
    elems.append(bullet("CategoriaModel → SubcategoriaModel[] (1:N, bidirecional via @Relationship inverse)"))
    elems.append(bullet("CategoriaPlanejadaModel → SubcategoriaPlanejadaModel[] (1:N, cascade delete)"))
    elems.append(bullet("CategoriaPlanejadaModel → CategoriaModel (referência à categoria original)"))
    elems.append(bullet("SubcategoriaPlanejadaModel → SubcategoriaModel (referência à subcategoria original)"))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_transacoes():
    elems = []
    elems += section("3. Regras de Negócio — Transações")

    # RN-01
    elems.append(rule("RN-01", "Validação de Valor"))
    elems.append(bullet("O valor (<b>amount</b>) de uma transação deve ser <b>estritamente maior que zero</b>."))
    elems.append(bullet("Valores zerados ou negativos são rejeitados antes do salvamento (<i>AddTransactionViewModel.criarTransacaoEChamarClosure</i>)."))
    elems.append(bullet("Valores são armazenados como <b>Double</b> e exibidos com 2 casas decimais no formato BRL (R$ 0,00)."))
    elems.append(spacer(0.15))

    # RN-02
    elems.append(rule("RN-02", "Classificação: Despesa vs. Receita"))
    elems.append(bullet("Toda transação é classificada como <b>Despesa</b> ou <b>Receita</b> via o flag <i>isIncome: Bool</i>."))
    elems.append(bullet("Transações vinculadas à categoria <b>\"Renda\"</b> são automaticamente marcadas como receita (<i>isIncome = true</i>), independentemente do tipo selecionado pelo usuário na UI."))
    elems.append(bullet("Ao criar uma <b>despesa</b>: a categoria \"Renda\" <b>não aparece</b> nas opções de seleção."))
    elems.append(bullet("Ao criar uma <b>receita</b>: <b>somente</b> a categoria \"Renda\" é apresentada."))
    elems.append(spacer(0.15))

    # RN-03
    elems.append(rule("RN-03", "Categorização Obrigatória"))
    elems.append(bullet("Toda transação <b>deve ter categoria e subcategoria</b> associadas para ser salva."))
    elems.append(bullet("A ausência de qualquer um desses campos bloqueia o salvamento."))
    elems.append(bullet("A descrição (<i>expenseDescription</i>) é <b>opcional</b>."))
    elems.append(spacer(0.15))

    # RN-04
    elems.append(rule("RN-04", "Recorrência de Transações"))
    elems.append(body("Uma transação pode ser configurada como recorrente com as seguintes frequências:"))
    freq = [
        ("Nunca", "Padrão — transação pontual"),
        ("Diariamente", "Repete a cada 1 dia"),
        ("Semanalmente", "Repete a cada 7 dias"),
        ("A cada 10 dias", "Repete a cada 10 dias"),
        ("Mensalmente", "Repete a cada 1 mês"),
        ("Anualmente", "Repete a cada 1 ano"),
    ]
    elems.append(table(["Opção", "Comportamento"], freq, col_widths=[5*cm, 12.5*cm]))
    elems.append(spacer(0.1))
    elems.append(bullet("Transações recorrentes <b>não geram registros físicos</b> para cada ocorrência — o sistema projeta instâncias virtuais (<i>DisplayableExpense</i>) calculando as datas dentro do intervalo mensal em tempo de exibição."))
    elems.append(bullet("A data de término da recorrência é <b>opcional</b>. Sem ela, o padrão sugerido na UI é <b>1 ano a partir da data inicial</b>."))
    elems.append(spacer(0.15))

    # RN-05
    elems.append(rule("RN-05", "Exclusão de Ocorrências Recorrentes"))
    elems.append(body("Ao excluir uma ocorrência de transação recorrente, o usuário seleciona o escopo:"))
    escopos = [
        ("Esta ocorrência apenas", "Adiciona a data às excludedDates da série; as demais ocorrências permanecem"),
        ("Esta e todas as futuras", "Define endDate da série para o dia anterior à ocorrência selecionada"),
        ("Toda a série", "Deleta o ExpenseModel original do banco de dados"),
    ]
    elems.append(table(["Escopo", "Comportamento no Banco"], escopos, col_widths=[6*cm, 11.5*cm]))
    elems.append(spacer(0.1))
    elems.append(bullet("Se ao aplicar \"Esta e futuras\" a nova <i>endDate</i> resultante for <b>anterior à data de início</b> da série, toda a série é deletada como fallback."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_categorias():
    elems = []
    elems += section("4. Regras de Negócio — Categorias")

    elems.append(rule("RN-06", "Seed de Dados Iniciais"))
    elems.append(bullet("O sistema popula <b>7 categorias pré-definidas</b> na <b>primeira inicialização</b> (quando não há categorias no banco)."))
    elems.append(bullet("As categorias seed possuem <b>IDs fixos e determinísticos</b> (<i>SeedIDs</i>), usados em regras hardcoded do sistema."))
    elems.append(bullet("O seed nunca é re-executado se já existirem categorias — operação idempotente."))
    elems.append(spacer(0.1))

    cats = [
        ("Renda", "Verde", "Exclusiva para receitas; papel especial no sistema"),
        ("Comidas e Bebidas", "Teal", "Despesa"),
        ("Entretenimento", "Rosa", "Despesa"),
        ("Habitação", "Laranja", "Despesa"),
        ("Transporte", "Roxo", "Despesa"),
        ("Estilo de Vida", "Azul", "Despesa"),
        ("Diversos", "Marrom", "Despesa"),
    ]
    elems.append(table(["Categoria", "Cor Padrão", "Papel"], cats, col_widths=[5.5*cm, 4*cm, 8*cm]))
    elems.append(spacer(0.2))

    elems.append(rule("RN-07", "Subcategorias Favoritas"))
    elems.append(bullet("Cada subcategoria rastreia um <b>contador de uso</b> (<i>usageCount</i>), incrementado a cada seleção ao criar uma transação."))
    elems.append(bullet("As <b>6 subcategorias mais utilizadas</b> são exibidas como atalhos na tela de seleção de categoria."))
    elems.append(bullet("A lista de favoritos é filtrada pelo tipo de transação: subcategorias de \"Renda\" nunca aparecem em favoritos de despesas e vice-versa."))
    elems.append(spacer(0.1))

    elems.append(rule("RN-08", "Edição de Categorias"))
    elems.append(bullet("A edição de categorias está estruturada na UI (<i>CategoriesViewEdit</i>), mas as ações de <b>adicionar e deletar categorias/subcategorias estão comentadas</b> e não funcionais no estado atual."))
    elems.append(bullet("Somente visualização está ativa."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_planejamento():
    elems = []
    elems += section("5. Regras de Negócio — Planejamento Orçamentário")

    elems.append(rule("RN-09", "Escopo Mensal"))
    elems.append(bullet("O planejamento é <b>por mês/ano</b>. O campo <i>mesAno</i> sempre armazena o <b>primeiro dia do mês</b> (<i>startOfMonth()</i>)."))
    elems.append(bullet("Uma mesma categoria <b>só pode ter um planejamento por mês</b>. Tentativas de adicionar uma categoria já planejada redirecionam para inclusão de subcategoria na entrada existente."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-10", "Estrutura Hierárquica"))
    elems.append(bullet("O planejamento tem dois níveis: <b>Categoria → Subcategoria</b>."))
    elems.append(bullet("Uma subcategoria só pode aparecer <b>uma vez</b> no planejamento de uma categoria em um dado mês (unicidade verificada antes do insert)."))
    elems.append(bullet("Cada subcategoria planejada possui um <b><i>valorPlanejado</i> ≥ 0</b>."))
    elems.append(bullet("O valor total planejado de uma categoria = <b>Σ valorPlanejado</b> das suas subcategorias."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-11", "Cascade Delete Automático"))
    elems.append(bullet("Ao remover subcategorias planejadas, se a <b>categoria planejada ficar sem subcategorias</b>, ela é <b>automaticamente deletada</b>."))
    elems.append(bullet("Este comportamento é garantido tanto pela regra de negócio no ViewModel quanto pela configuração <i>deleteRule: .cascade</i> no modelo."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-12", "Cópia de Planejamento entre Meses"))
    elems.append(bullet("É possível copiar o planejamento do mês atual para o <b>próximo mês</b>."))
    elems.append(bullet("Categorias que <b>já existem no mês de destino são ignoradas</b> (sem sobrescrever dados existentes)."))
    elems.append(bullet("Os valores planejados das subcategorias são <b>copiados integralmente</b>."))
    elems.append(bullet("Se não há planejamento no mês atual, a operação é bloqueada com alerta ao usuário."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-13", "Zerar Planejamento do Mês"))
    elems.append(bullet("O usuário pode <b>zerar completamente</b> o planejamento do mês atual."))
    elems.append(bullet("Esta ação deleta todos os registros <i>CategoriaPlanejadaModel</i> do mês (e por cascade todas as <i>SubcategoriaPlanejadaModel</i> associadas)."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_dashboard():
    elems = []
    elems += section("6. Regras de Negócio — Dashboard e Métricas")

    elems.append(rule("RN-14", "Cálculos Financeiros do Mês"))
    metricas = [
        ("Total Gasto", "Σ amount de todas as despesas do mês"),
        ("Total de Receitas", "Σ amount de todas as receitas do mês"),
        ("Total Planejado", "Σ valorPlanejado de todas as subcategorias planejadas do mês"),
        ("Saldo Restante", "Total Planejado − Gasto em Categorias Planejadas"),
        ("Progresso por Categoria", "min(gasto / planejado, 1.0) — limitado a 100%"),
    ]
    elems.append(table(["Métrica", "Fórmula"], metricas, col_widths=[6*cm, 11.5*cm]))
    elems.append(spacer(0.1))
    elems.append(bullet("O <b>Saldo Restante</b> considera apenas gastos em subcategorias que estão <b>dentro do planejamento</b>. Gastos em subcategorias não planejadas <b>não reduzem</b> o saldo restante."))
    elems.append(bullet("As categorias no dashboard são exibidas em <b>ordem decrescente</b> de gasto total."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-15", "Gráfico Diário de Despesas"))
    elems.append(bullet("O gráfico exibe um ponto para <b>cada dia do mês</b>, mesmo que o valor seja zero."))
    elems.append(bullet("Transações recorrentes contribuem para o gasto do dia da <b>ocorrência virtual</b>, não apenas para a data original da série."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_navegacao():
    elems = []
    elems += section("7. Regras de Negócio — Navegação Temporal")

    elems.append(rule("RN-16", "Mês Sincronizado"))
    elems.append(bullet("O mês navegado é <b>sincronizado entre Home, Planejamento e Despesas</b> via publishers Combine (<i>objectWillChange</i> + <i>@Published</i> sinks)."))
    elems.append(bullet("A data de referência interna é sempre o <b>início do mês</b> (<i>startOfMonth()</i> — dia 1, 00:00:00)."))
    elems.append(bullet("A navegação é incremental: <b>±1 mês</b> por vez, usando <i>Calendar.date(byAdding: .month)</i>."))
    elems.append(bullet("Ao mudar o mês em qualquer tela, as outras são notificadas e recalculam seus dados automaticamente."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_seguranca():
    elems = []
    elems += section("8. Regras de Negócio — Segurança e Onboarding")

    elems.append(rule("RN-17", "Autenticação Biométrica (Planejada)"))
    elems.append(bullet("A estrutura para <b>Face ID / Touch ID</b> está prevista (<i>AuthViewModel</i>, <i>BiometricView</i>)."))
    elems.append(bullet("Os ViewModels correspondentes estão <b>vazios</b> — funcionalidade <b>não implementada</b>."))
    elems.append(spacer(0.15))

    elems.append(rule("RN-18", "Onboarding e Dicas (Planejados)"))
    elems.append(bullet("Existe estrutura para fluxo de boas-vindas (<i>OnboardingView</i>, <i>WelcomeView</i>) e seção de dicas financeiras (<i>TipsView</i>)."))
    elems.append(bullet("Os ViewModels correspondentes (<i>OnboardingViewModel</i>, <i>TipsViewModel</i>, <i>Tip</i>) estão <b>vazios</b>."))
    elems.append(spacer(0.3))
    elems.append(hr())
    return elems

def build_gaps():
    elems = []
    elems += section("9. Lacunas Identificadas — Gap Analysis")

    elems.append(body(
        "As lacunas abaixo foram identificadas pela inspeção do código-fonte. Representam "
        "funcionalidades ausentes, comentadas ou estruturadas mas não implementadas."
    ))
    elems.append(spacer(0.15))

    gaps = [
        ("L-01", "Alto", "Criação/edição/exclusão de categorias customizadas desabilitada — código comentado em CategoriesViewEdit"),
        ("L-02", "Alto", "Autenticação biométrica não implementada — dados financeiros pessoais sem proteção de acesso"),
        ("L-03", "Médio", "Validação de valor negativo apenas no ViewModel, não no Model — integridade fraca no nível de dados"),
        ("L-04", "Médio", "Sem suporte a múltiplas moedas — locale fixo em pt_BR/BRL"),
        ("L-05", "Médio", "Sem exportação de dados (PDF/CSV) — sem portabilidade para o usuário"),
        ("L-06", "Médio", "Sem metas de poupança — funcionalidade chave de gestão financeira ausente"),
        ("L-07", "Médio", "Sem alertas de orçamento excedido (push notifications) — usuário não é notificado proativamente"),
        ("L-08", "Baixo", "Dicas financeiras (TipsView/TipsViewModel) não implementadas"),
        ("L-09", "Baixo", "usageCount não é decrementado ao excluir transação — favoritos podem ficar desatualizados"),
        ("L-10", "Baixo", "Sem sincronização iCloud — dados perdidos ao trocar de dispositivo"),
    ]

    # colorir impacto
    data = [
        [Paragraph("<b>ID</b>", STYLES["table_header"]),
         Paragraph("<b>Impacto</b>", STYLES["table_header"]),
         Paragraph("<b>Descrição</b>", STYLES["table_header"])]
    ]
    impact_hex = {"Alto": "D62828", "Médio": "E07B39", "Baixo": "2D6A9F"}
    for gid, impact, desc in gaps:
        hx = impact_hex.get(impact, "2B2D42")
        data.append([
            Paragraph(f"<b>{gid}</b>", STYLES["table_cell"]),
            Paragraph(f"<font color='#{hx}'><b>{impact}</b></font>", STYLES["table_cell"]),
            Paragraph(desc, STYLES["table_cell"]),
        ])

    t = Table(data, colWidths=[1.8*cm, 2.5*cm, 13.2*cm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), VERDE),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [BRANCO, CINZA_CLARO]),
        ("GRID", (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ("LEFTPADDING", (0,0), (-1,-1), 7),
        ("RIGHTPADDING", (0,0), (-1,-1), 7),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
    ]))
    elems.append(t)
    elems.append(spacer(0.3))
    elems.append(hr())
    elems.append(spacer(0.3))
    elems.append(Paragraph(
        "Documento gerado automaticamente por análise de código-fonte — CashUp v0.1 · 2026",
        STYLES["footer"]
    ))
    return elems

# ── Numeração de páginas ─────────────────────────────────────────────────────

def on_page(canvas, doc):
    canvas.saveState()
    # linha inferior
    canvas.setStrokeColor(VERDE_CLARO)
    canvas.setLineWidth(0.5)
    canvas.line(1.5*cm, 1.5*cm, A4[0] - 1.5*cm, 1.5*cm)
    # número
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#9E9E9E"))
    canvas.drawRightString(A4[0] - 1.5*cm, 1.1*cm, f"Página {doc.page}")
    canvas.drawString(1.5*cm, 1.1*cm, "CashUp — Regras de Negócio")
    canvas.restoreState()

# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    doc = SimpleDocTemplate(
        OUTPUT,
        pagesize=A4,
        leftMargin=1.5*cm,
        rightMargin=1.5*cm,
        topMargin=1.8*cm,
        bottomMargin=2.2*cm,
        title="CashUp — Regras de Negócio",
        author="Claude Code — Análise de Código-Fonte",
        subject="Análise de Negócio e Regras de Negócio do CashUp",
    )

    story = []
    story += build_cover()
    story += build_toc()
    story += build_visao_geral()
    story += build_entidades()
    story += build_transacoes()
    story += build_categorias()
    story += build_planejamento()
    story += build_dashboard()
    story += build_navegacao()
    story += build_seguranca()
    story += build_gaps()

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    print(f"PDF gerado: {OUTPUT}")

if __name__ == "__main__":
    main()
