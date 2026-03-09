//
//  PlanningPlanejarView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//


import SwiftUI
import SwiftData
import Charts

struct PlanningPlanejarView: View {
    @ObservedObject var viewModel: PlanningViewModel
    
    @Binding var isEditing: Bool
    @Binding var subcategoriasPlanejadasSelecionadasParaDelecao: Set<UUID>
    @State private var isCategorySheetPresented = false
    @State private var selectedSubcategoryFromSheet: SubcategoriaModel? = nil
    @State private var selectedCategoryFromSheet: CategoriaModel? = nil
    @State private var showResetConfirmation = false
    @State private var showDuplicateAlert = false
    
    
    @Query var categoriasPlanejadasDoMesQuery: [CategoriaPlanejadaModel]

   init(viewModel: PlanningViewModel,
        isEditing: Binding<Bool>,
        subcategoriasSelecionadas: Binding<Set<UUID>>) {
       self.viewModel = viewModel
       self._isEditing = isEditing
       self._subcategoriasPlanejadasSelecionadasParaDelecao = subcategoriasSelecionadas

       let monthToFilter = viewModel.currentMonth.startOfMonth()
       let predicate = #Predicate<CategoriaPlanejadaModel> {
           $0.mesAno == monthToFilter
       }

       _categoriasPlanejadasDoMesQuery = Query(filter: predicate, sort: [], animation: .default)
   }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    despesasPlanejadasCard
                    listaCategoriasPlanejadasView()
                    botaoAdicionarCategoriaAoPlanejamento
                    Spacer()
                    rodapePlanejamento
                }
            }
            .fullScreenCover(isPresented: $isCategorySheetPresented) {
                let categoriesVM = CategoriesViewModel(
                    modelContext: viewModel.modelContext,
                    transactionType: .despesa
                )
                CategorySelectionSheet(
                    viewModel: categoriesVM,
                    selectedSubcategoryModel: $selectedSubcategoryFromSheet,
                    isPresented: $isCategorySheetPresented,
                    selectedCategoryModel: $selectedCategoryFromSheet
                )
                .environment(\.modelContext, viewModel.modelContext)
            }
            .onChange(of: selectedSubcategoryFromSheet) { oldValue, newValue in
                guard let subModel = newValue else {
                    if newValue == nil {
                        selectedCategoryFromSheet = nil
                    }
                    return
                }

                let catModelParaProcessar: CategoriaModel?
                if let directCat = selectedCategoryFromSheet, directCat.id == subModel.categoria?.id {
                    catModelParaProcessar = directCat
                } else if let parentCat = subModel.categoria {
                    catModelParaProcessar = parentCat
                    DispatchQueue.main.async {
                        if self.selectedCategoryFromSheet?.id != parentCat.id {
                            self.selectedCategoryFromSheet = parentCat
                        }
                    }
                } else {
                    print("Erro Crítico: Subcategoria '\(subModel.nome)' selecionada não tem uma categoria pai associada.")
                    DispatchQueue.main.async {
                        self.selectedSubcategoryFromSheet = nil
                        self.selectedCategoryFromSheet = nil
                    }
                    return
                }

                guard let finalCatModel = catModelParaProcessar else {
                    print("Erro: Categoria final para processamento é nil após seleção de subcategoria.")
                    DispatchQueue.main.async {
                        self.selectedSubcategoryFromSheet = nil
                        self.selectedCategoryFromSheet = nil
                    }
                    return
                }

                processarSelecaoDoSheet(subcategoria: subModel, categoria: finalCatModel)
            }

            if showDuplicateAlert {
                alertDuplicado
            }
        }
        .animation(.easeInOut, value: showDuplicateAlert)
        .hideKeyboardOnTap()
    }
    
    private func processarSelecaoDoSheet(subcategoria: SubcategoriaModel, categoria: CategoriaModel) {
        let adicionouComSucesso: Bool
        
        if categoriasPlanejadasDoMesQuery.contains(where: { $0.categoriaOriginal?.id == categoria.id }) {
            adicionouComSucesso = viewModel.adicionarSubcategoriaAoPlanejamento(
                subcategoriaModel: subcategoria,
                toCategoriaModel: categoria
            )
        } else {
            adicionouComSucesso = viewModel.adicionarNovaCategoriaAoPlanejamento(
                categoriaModel: categoria,
                comSubcategoriaInicial: subcategoria
            )
        }
        
        if !adicionouComSucesso {
            showDuplicateAlert = true
        }
        
        DispatchQueue.main.async {
            selectedSubcategoryFromSheet = nil
            selectedCategoryFromSheet = nil
        }
    }

    private var despesasPlanejadasCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                let plannedCategoriesWithValues = categoriasPlanejadasDoMesQuery
                    .sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
                    .filter { viewModel.totalParaCategoriaPlanejada($0) > 0 }

                if viewModel.valorTotalPlanejadoParaMesAtual() > 0 && !plannedCategoriesWithValues.isEmpty {
                    Chart(plannedCategoriesWithValues) { categoriaPModel in
                        SectorMark(
                            angle: .value("Valor", viewModel.totalParaCategoriaPlanejada(categoriaPModel)),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .foregroundStyle(categoriaPModel.corCategoriaOriginal)
                        .cornerRadius(5)
                        .accessibilityLabel(categoriaPModel.nomeCategoriaOriginal)
                        .accessibilityValue("\(viewModel.calcularPorcentagemTotal(paraCategoriaPlanejada: categoriaPModel), specifier: "%.0f")%")
                    }
                    .frame(width: 80, height: 80)
                } else {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.secondary.opacity(0.4))
                        .frame(width: 80, height: 80, alignment: .center)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Despesas Planejadas")
                        .font(.headline)
                    Text(viewModel.valorTotalPlanejadoParaMesAtual(), format: .currency(code: "BRL"))
                        .font(.title2.bold())
                        .foregroundColor(viewModel.valorTotalPlanejadoParaMesAtual() > 0 ? .primary : .secondary)
                }
                Spacer()
            }

            let sortedCategorias = categoriasPlanejadasDoMesQuery.sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
            if !sortedCategorias.isEmpty {
                Text("Resumo por Categoria:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(sortedCategorias) { categoriaPlanejadaModel in
                    categoriaResumo(categoriaPlanejadaModel)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func categoriaResumo(_ categoriaPModel: CategoriaPlanejadaModel) -> some View {
        let total = viewModel.totalParaCategoriaPlanejada(categoriaPModel)
        let percentual = viewModel.calcularPorcentagemTotal(paraCategoriaPlanejada: categoriaPModel)
        
        VStack(spacing: 4) {
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(categoriaPModel.corCategoriaOriginal)
                    .frame(width: 12, height: 12)
                    .padding(.leading, 4)
                
                Text(categoriaPModel.nomeCategoriaOriginal)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(percentual, specifier: "%.0f")%")
                    .font(.subheadline)
                    .frame(width: 50, alignment: .trailing)
                
                Text(total, format: .currency(code: "BRL"))
                    .font(.subheadline.weight(.medium))
                    .frame(width: 100, alignment: .trailing)
            }
            Divider().padding(.top, 4)
        }
    }
    
    @ViewBuilder
    private func listaCategoriasPlanejadasView() -> some View {
        let sortedCategorias = categoriasPlanejadasDoMesQuery.sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
        if sortedCategorias.isEmpty && !isEditing {
            Text("Nenhuma categoria planejada para este mês.\nToque em \"Adicionar Categoria\" para começar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)

            Text("Para copiar o planejamento para o mês seguinte,\n utilize o botao de documento no topo da tela.")
               .font(.subheadline)
               .foregroundStyle(.secondary)
               .multilineTextAlignment(.center)
               .padding()
               .frame(maxWidth: .infinity, alignment: .center)
        } else {
            ForEach(sortedCategorias) { catPlanModel in
                categoriaPlanejadaView(catPlanModel)
            }
        }
    }
    
    @ViewBuilder
    private func categoriaPlanejadaView(_ catPlanModel: CategoriaPlanejadaModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CategoriasViewIcon(
                    systemName: catPlanModel.iconCategoriaOriginal,
                    cor: catPlanModel.corCategoriaOriginal,
                    size: 24
                )
                Text(catPlanModel.nomeCategoriaOriginal)
                    .font(.headline)
                Spacer()
            }
            Divider()
            
            if let subcategorias = catPlanModel.subcategoriasPlanejadas, !subcategorias.isEmpty {
                ForEach(subcategorias.sorted(by: { $0.subcategoriaOriginal?.nome ?? "" < $1.subcategoriaOriginal?.nome ?? ""})) { subPlanModel in
                    SubcategoriaPlanejadaRowView(
                        subPlanejadaModel: subPlanModel,
                        corIconeCategoriaPai: catPlanModel.corCategoriaOriginal,
                        isEditing: isEditing,
                        isSelected: subcategoriasPlanejadasSelecionadasParaDelecao.contains(subPlanModel.id),
                        toggleSelection: {
                            if subcategoriasPlanejadasSelecionadasParaDelecao.contains(subPlanModel.id) {
                                subcategoriasPlanejadasSelecionadasParaDelecao.remove(subPlanModel.id)
                            } else {
                                subcategoriasPlanejadasSelecionadasParaDelecao.insert(subPlanModel.id)
                            }
                        },
                        valorPlanejadoStringBinding: viewModel.bindingParaValorPlanejado(subItem: subPlanModel)
                    )
                }
            } else if !isEditing {
                Text("Nenhuma subcategoria planejada aqui.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                    .padding(.vertical, 4)
            }
            
            if !isEditing {
                Button(action: {
                    self.selectedCategoryFromSheet = catPlanModel.categoriaOriginal
                    self.selectedSubcategoryFromSheet = nil
                    isCategorySheetPresented = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Adicionar Subcategoria")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var rodapePlanejamento: some View {
        HStack {
            Text("Planejamento para:\n\(viewModel.currentMonth.formatted(.dateTime.month(.wide).year(.defaultDigits)))")
                .font(.caption2)
                .lineLimit(2)
            Spacer()
            Button("Zerar Planejamento") {
                showResetConfirmation = true
            }
            .font(.caption)
            .foregroundColor(.red)
            .alert("Confirmação", isPresented: $showResetConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Confirmar", role: .destructive) {
                    viewModel.zerarPlanejamentoDoMes()
                }
            } message: {
                Text("Você tem certeza que deseja zerar o planejamento deste mês? Esta ação não pode ser desfeita.")
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var alertDuplicado: some View {
        VStack {
            Spacer()
            Text("Subcategoria já adicionada a este planejamento.")
                .padding()
                .background(Color.orange.opacity(0.85))
                .foregroundStyle(.white)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut) {
                    showDuplicateAlert = false
                }
            }
        }
    }
    
    private var botaoAdicionarCategoriaAoPlanejamento: some View {
        Button(action: {
            selectedCategoryFromSheet = nil
            selectedSubcategoryFromSheet = nil
            isCategorySheetPresented = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                Text("Adicionar Categoria ao Planejamento")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 30)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: Sheet de Configuração de Repetição
struct RepeatSettingsSheetView: View {
    @Binding var repetitionData: RepetitionData
    var startDateForRepetition: Date
    @Environment(\.dismiss) var dismiss

    @State private var localRepeatOption: RepeatOption
    @State private var localRepeatEndDate: Date?
    @State private var hasEndDateToggle: Bool

    init(repetitionData: Binding<RepetitionData>, startDateForRepetition: Date) {
        self._repetitionData = repetitionData
        self.startDateForRepetition = startDateForRepetition
        
        let initialData = repetitionData.wrappedValue
        self._localRepeatOption = State(initialValue: initialData.repeatOption)
        self._localRepeatEndDate = State(initialValue: initialData.endDate)
        self._hasEndDateToggle = State(initialValue: initialData.endDate != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Frequência da Repetição")) {
                    Picker("Repetir", selection: $localRepeatOption) {
                        ForEach(RepeatOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .onChange(of: localRepeatOption) { _, newOption in
                        if newOption == .nunca {
                            localRepeatEndDate = nil
                            hasEndDateToggle = false
                        }
                    }
                }

                if localRepeatOption != .nunca {
                    Section(header: Text("Data de Término da Repetição (Opcional)")) {
                        Toggle("Definir data de término", isOn: $hasEndDateToggle)
                            .onChange(of: hasEndDateToggle) { _, newValue in
                                if !newValue {
                                    localRepeatEndDate = nil
                                } else if localRepeatEndDate == nil {
                                    localRepeatEndDate = Calendar.current.date(byAdding: .year, value: 1, to: startDateForRepetition) ?? startDateForRepetition
                                }
                            }

                        if hasEndDateToggle {
                            DatePicker(
                                "Parar em",
                                selection: Binding(
                                    get: { localRepeatEndDate ?? Calendar.current.date(byAdding: .year, value: 1, to: startDateForRepetition) ?? startDateForRepetition },
                                    set: { localRepeatEndDate = $0 }
                                ),
                                in: startDateForRepetition...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                        }
                    }
                }
            }
            .navigationTitle("Configurar Repetição")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
