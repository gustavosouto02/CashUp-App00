import SwiftUI

struct RecommendedPlanningSheet: View {
    @ObservedObject var viewModel: RecommendedPlanningViewModel
    let mes: Date
    let onPlanejamentoAplicado: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmacaoSubstituicao: Bool = false
    @State private var itemParaTrocarSubcategoria: RecommendedPlanningItem? = nil
    @State private var grupoParaAdicionarSubcategoria: Regra503020Grupo? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cardRendaMensal
                    cardResumo503020
                    secoesItensRecomendados
                    if viewModel.temPlanejamentoExistente {
                        cardAvisoPlanejamentoExistente
                    }
                    botaoAplicar
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                }
            )
            .hideKeyboardOnTap()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Planejamento Recomendado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        tentarAplicar()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.itensRecomendados.isEmpty || viewModel.isAplicando)
                }
            }
            .onAppear {
                viewModel.carregarDados(mes: mes)
            }
            .sheet(item: $itemParaTrocarSubcategoria) { item in
                SubcategoriaPickerSheet(
                    categoria: item.categoria,
                    subcategoriaAtualID: item.subcategoria?.id,
                    idsIndisponiveis: viewModel.idsSubcategoriasUsadas(excluindo: item.id),
                    valorAtual: item.valorSugerido,
                    onSelecionar: { novaSub in
                        viewModel.atualizarSubcategoriaItem(id: item.id, novaSubcategoria: novaSub)
                    }
                )
            }
            .sheet(item: $grupoParaAdicionarSubcategoria) { grupo in
                RecommendedAddSubcategorySheet(
                    categorias: viewModel.categoriasDisponiveis,
                    grupo: grupo,
                    idsIndisponiveis: viewModel.idsSubcategoriasUsadas(),
                    onSelecionar: { novaSub in
                        _ = viewModel.adicionarItem(subcategoria: novaSub, grupo: grupo)
                    }
                )
            }
            .alert("Substituir Planejamento?", isPresented: $showConfirmacaoSubstituicao) {
                Button("Cancelar", role: .cancel) { }
                Button("Substituir", role: .destructive) {
                    executarAplicacao()
                }
            } message: {
                Text("Este mês já possui categorias planejadas. Deseja substituir pelo planejamento recomendado?")
            }
            .alert("Sucesso", isPresented: $viewModel.showAlertaSucesso) {
                Button("OK") {
                    onPlanejamentoAplicado()
                    dismiss()
                }
            } message: {
                Text("O planejamento recomendado foi aplicado com sucesso!")
            }
            .alert("Erro", isPresented: $viewModel.showAlertaErro) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.mensagemErro)
            }
        }
    }

    private var cardRendaMensal: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sua Renda Mensal")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.temRendaDetectada {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.usarRendaDetectada()
                    }) {
                        Text("Usar detectada (\(BRLCurrencyFormatter.string(from: viewModel.rendaDetectada)))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            CurrencyAmountField(amount: $viewModel.rendaInformada)
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.rendaInformada) { _, _ in
                    viewModel.recalcular()
                }

            Text("O valor acima é a base para calcular as porcentagens 50% / 30% / 20%.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private var cardResumo503020: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Distribuição 50 / 30 / 20")
                    .font(.headline)
                Text("Equilíbrio financeiro sugerido com base na sua renda.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Barra colorida proporcional com mais respiro e cantos arredondados
            GeometryReader { proxy in
                HStack(spacing: 6) {
                    let largura = proxy.size.width
                    let percNec = max(min(viewModel.percentualPorGrupo(.necessidades) / 100.0, 1.0), 0.05)
                    let percDes = max(min(viewModel.percentualPorGrupo(.desejos) / 100.0, 1.0), 0.05)
                    let percPou = max(min(viewModel.percentualPorGrupo(.futuroPoupanca) / 100.0, 1.0), 0.05)
                    let soma = percNec + percDes + percPou

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Regra503020Grupo.necessidades.cor)
                        .frame(width: (largura - 12) * (percNec / soma))

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Regra503020Grupo.desejos.cor)
                        .frame(width: (largura - 12) * (percDes / soma))

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Regra503020Grupo.futuroPoupanca.cor)
                        .frame(width: (largura - 12) * (percPou / soma))
                }
            }
            .frame(height: 12)
            .padding(.vertical, 4)

            // Cards individuais bem separados para cada grupo
            HStack(spacing: 10) {
                ForEach(Regra503020Grupo.allCases) { grupo in
                    miniCardGrupo(grupo)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func miniCardGrupo(_ grupo: Regra503020Grupo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(grupo.cor)
                    .frame(width: 8, height: 8)
                Text("\(Int(grupo.percentualAlvo))%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(grupo.cor)
                Spacer()
            }

            Text(grupo.rotuloCard)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(BRLCurrencyFormatter.string(from: viewModel.totalPorGrupo(grupo)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(grupo.cor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(grupo.cor.opacity(0.2), lineWidth: 1)
        )
    }

    private var secoesItensRecomendados: some View {
        VStack(spacing: 20) {
            ForEach(Regra503020Grupo.allCases) { grupo in
                let itens = viewModel.itens(doGrupo: grupo)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(grupo.cor)
                                .frame(width: 8, height: 8)
                            Text(grupo.rawValue)
                                .font(.headline)
                            Spacer()
                            Text(grupo == .futuroPoupanca ? "Alvo: 20% (Guardar Dinheiro)" : "Alvo: \(Int(grupo.percentualAlvo))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(grupo.cor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(grupo.cor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Text(grupo.descricao)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        if itens.isEmpty {
                            Text("Nenhuma categoria adicionada neste grupo.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                        } else {
                            ForEach(itens) { item in
                                SwipeActionRow {
                                    linhaItemRecomendado(item: item)
                                } onDelete: {
                                    withAnimation {
                                        viewModel.removerItem(id: item.id)
                                    }
                                }
                                if item.id != itens.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }

                        Divider()

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            grupoParaAdicionarSubcategoria = grupo
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Adicionar Subcategoria")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func linhaItemRecomendado(item: RecommendedPlanningItem) -> some View {
        HStack(spacing: 12) {
            CategoriasViewIcon(
                systemName: item.categoria.icon,
                cor: item.categoria.color,
                size: 22
            )

            Button {
                itemParaTrocarSubcategoria = item
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.categoria.nome)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Text(item.subcategoria?.nome ?? "Selecionar Subcategoria")
                            .font(.subheadline)
                            .foregroundStyle(item.subcategoria == nil ? .blue : .secondary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            CompactCurrencyTextField(
                amount: Binding(
                    get: {
                        if let index = viewModel.itensRecomendados.firstIndex(where: { $0.id == item.id }) {
                            return viewModel.itensRecomendados[index].valorSugerido
                        }
                        return item.valorSugerido
                    },
                    set: { novo in viewModel.atualizarValorItem(id: item.id, novoValor: novo) }
                )
            )
            .id(item.id)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var cardAvisoPlanejamentoExistente: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $viewModel.substituirPlanejamentoExistente) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Substituir planejamento atual")
                        .font(.subheadline.weight(.medium))
                    Text("Você já possui categorias planejadas neste mês. Desmarque para mesclar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    private var botaoAplicar: some View {
        Button(action: {
            tentarAplicar()
        }) {
            HStack(spacing: 8) {
                if viewModel.isAplicando {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Aplicar Planejamento Recomendado")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color(red: 0.35, green: 0.38, blue: 0.95)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.itensRecomendados.isEmpty || viewModel.isAplicando)
        .padding(.horizontal)
        .accessibilityIdentifier("recommended_planning_apply_button")
    }

    private func tentarAplicar() {
        if viewModel.temPlanejamentoExistente && viewModel.substituirPlanejamentoExistente {
            showConfirmacaoSubstituicao = true
        } else {
            executarAplicacao()
        }
    }

    private func executarAplicacao() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        _ = viewModel.aplicarAoPlanejamento(mes: mes)
    }
}
