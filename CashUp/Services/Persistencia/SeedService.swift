import SwiftData
import SwiftUI

struct CategoriaSeedInfo {
    let id: UUID
    let nome: String
    let cor: Color
    let icon: String
    let subcategorias: [SubcategoriaSeedInfo]
    var introduzidoNaVersao: Int = 1
}

struct SubcategoriaSeedInfo {
    let id: UUID
    let nome: String
    let icon: String
    var introduzidoNaVersao: Int = 1
}

/// Catálogo do seed. Todo item novo leva `introduzidoNaVersao` igual à nova `versao`; a versão 1 é o catálogo da App Store 1.5.
enum SeedCatalogo {
    static let versao = 2

    static var todosIDs: Set<UUID> {
        Set(categorias.flatMap { [$0.id] + $0.subcategorias.map(\.id) })
    }

    static let categorias: [CategoriaSeedInfo] = [
        CategoriaSeedInfo(
            id: SeedIDs.idDiversos,
            nome: "Diversos",
            cor: Color(red: 0.35, green: 0.2, blue: 0.1),
            icon: "puzzlepiece",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubCustosBancarios, nome: "Custos Bancários", icon: "dollarsign.bank.building.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubDesconhecido, nome: "Desconhecido", icon: "questionmark.app.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubDiversosGerais, nome: "Diversos", icon: "archivebox.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubReserva, nome: "Reserva", icon: "shield.fill", introduzidoNaVersao: 2),
                SubcategoriaSeedInfo(id: SeedIDs.idSubRoupas, nome: "Roupas", icon: "tshirt"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubSaude, nome: "Saúde", icon: "heart.fill")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idEntretenimento,
            nome: "Entretenimento",
            cor: Color(red: 1.0, green: 0.39, blue: 0.51),
            icon: "gamecontroller",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubAcademia, nome: "Academia", icon: "dumbbell.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubAssinatura, nome: "Assinatura", icon: "rectangle.stack.badge.play.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubBoate, nome: "Boate", icon: "party.popper.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubBoliche, nome: "Boliche", icon: "figure.bowling"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCinema, nome: "Cinema", icon: "movieclapper.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubClube, nome: "Clube", icon: "beach.umbrella.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEletronicos, nome: "Eletrônicos", icon: "ipad"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEntretenimentoGeral, nome: "Entretenimento", icon: "gamecontroller"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEsportes, nome: "Esportes", icon: "soccerball.inverse"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubFerias, nome: "Férias", icon: "airplane.departure"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubPassatempo, nome: "Passatempo", icon: "book.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubShow, nome: "Show", icon: "music.microphone")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idComidasEBebidas,
            nome: "Comidas e Bebidas",
            cor: .teal,
            icon: "fork.knife",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubBebidas, nome: "Bebidas", icon: "wineglass.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCafe, nome: "Café", icon: "cup.and.heat.waves.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubComida, nome: "Comida", icon: "carrot.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubDoce, nome: "Doce", icon: "birthday.cake"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubFastFood, nome: "FastFood", icon: "takeoutbag.and.cup.and.straw"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubMantimentos, nome: "Mantimentos", icon: "cart.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubRestaurante, nome: "Restaurante", icon: "fork.knife.circle")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idHabitacao,
            nome: "Habitação",
            cor: .orange,
            icon: "house",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubAluguel, nome: "Aluguel", icon: "house.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubArtigosLar, nome: "Artigos para o lar", icon: "sofa.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubAgua, nome: "Água", icon: "drop"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubBanco, nome: "Banco", icon: "building.columns"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubContas, nome: "Contas", icon: "doc.plaintext"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEletricidade, nome: "Eletricidade", icon: "bolt.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubFinanciamentoHab, nome: "Financiamento", icon: "creditcard"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubHabitacaoGeral, nome: "Habitação", icon: "house.lodge.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubImpostos, nome: "Impostos", icon: "percent"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubJardim, nome: "Jardim", icon: "leaf"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubInternet, nome: "Internet", icon: "wifi"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubManutencaoHab, nome: "Manutenção", icon: "wrench.and.screwdriver"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubServico, nome: "Serviço", icon: "person.2.badge.gearshape.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubSeguroHab, nome: "Seguro", icon: "shield"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTelefone, nome: "Telefone", icon: "phone.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTV, nome: "TV", icon: "tv.fill")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idTransporte,
            nome: "Transporte",
            cor: Color(red: 0.75, green: 0.35, blue: 0.98),
            icon: "car",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubCarrosAplicativo, nome: "Carros de Aplicativo", icon: "car.2.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCustosCarro, nome: "Custos do Carro", icon: "car.circle.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEstacionamento, nome: "Estacionamento", icon: "parkingsign.circle.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubFinanciamentoTrans, nome: "Financiamento", icon: "creditcard"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubGasolina, nome: "Gasolina", icon: "fuelpump.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubManutencaoTrans, nome: "Manutenção", icon: "car.badge.gearshape.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubSeguroCarro, nome: "Seguro do Carro", icon: "car.side.lock.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTransportePublico, nome: "Transporte Público", icon: "bus"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTransporteGeral, nome: "Transporte", icon: "tram"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTaxi, nome: "Táxi", icon: "car.top.arrowtriangle.rear.left")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idEstiloDeVida,
            nome: "Estilo de Vida",
            cor: Color(red: 0.25, green: 0.45, blue: 0.75),
            icon: "figure.wave",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubAnimalEstimacao, nome: "Animal Estimação", icon: "pawprint.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCaridade, nome: "Caridade", icon: "hands.clap.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCompras, nome: "Compras", icon: "bag.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubComunidade, nome: "Comunidade", icon: "person.3.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubCreche, nome: "Creche", icon: "figure.and.child.holdinghands"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubDentista, nome: "Dentista", icon: "cross.case"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEscritorio, nome: "Escritório", icon: "folder.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEducacao, nome: "Educação", icon: "book.closed.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubEstiloVidaGeral, nome: "Estilo de Vida", icon: "figure.dance"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubFarmacia, nome: "Farmácia", icon: "pills.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubHotel, nome: "Hotel", icon: "bed.double.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubMedico, nome: "Médico", icon: "stethoscope.circle.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubPresente, nome: "Presente", icon: "gift.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubTrabalho, nome: "Trabalho", icon: "briefcase.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubViagem, nome: "Viagem", icon: "airplane")
            ]
        ),
        CategoriaSeedInfo(
            id: SeedIDs.idRenda,
            nome: "Renda",
            cor: Color(hue: 135/360, saturation: 0.8, brightness: 0.7),
            icon: "dollarsign",
            subcategorias: [
                SubcategoriaSeedInfo(id: SeedIDs.idSubInvestimentos, nome: "Investimentos", icon: "chart.line.uptrend.xyaxis"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubJuros, nome: "Juros", icon: "percent"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubPensao, nome: "Pensão", icon: "person.2.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubRendaGeral, nome: "Renda", icon: "arrow.down.to.line.circle.fill"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubSalario, nome: "Salário", icon: "banknote"),
                SubcategoriaSeedInfo(id: SeedIDs.idSubSalarioFamilia, nome: "Salário Família", icon: "house.and.flag.fill")
            ]
        )
    ]
}

fileprivate extension Color {
    func toRGBComponents() -> (red: Double, green: Double, blue: Double) {
        #if os(iOS) || os(tvOS) || os(watchOS)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return (Double(red), Double(green), Double(blue))
        #else
        return (0, 0, 0)
        #endif
    }
}

/// Aplica o catálogo sem recriar o que o usuário apagou: num store com dados, só entram itens de versões ainda não aplicadas.
/// O que o seed cria nasce com `atualizadoEm = .distantPast`: uma cópia do seed nunca conta como edição na deduplicação.
@MainActor
final class SeedService {
    private let settings: AppSettingsProtocol

    init(settings: AppSettingsProtocol) {
        self.settings = settings
    }

    func aplicar(em context: ModelContext, locale: Locale = .autoupdatingCurrent) throws {
        let categorias = try context.fetch(FetchDescriptor<CategoriaModel>())
        let subcategoriaIDs = Set(try context.fetch(FetchDescriptor<SubcategoriaModel>()).map(\.id))
        let removidos = Set(try context.fetch(FetchDescriptor<SeedRemocaoModel>()).map(\.seedID))
        let mapaCategorias = Dictionary(categorias.map { ($0.id, $0) }, uniquingKeysWith: { primeira, _ in primeira })
        let versaoBase = versaoJaAplicada(storeVazio: categorias.isEmpty && subcategoriaIDs.isEmpty)

        func deveInserir(id: UUID, versao: Int) -> Bool {
            versao > versaoBase && !removidos.contains(id)
        }

        var houveAlteracao = false
        for categoriaSeed in SeedCatalogo.categorias {
            let categoria: CategoriaModel
            var categoriaCriadaAgora = false
            if let existente = mapaCategorias[categoriaSeed.id] {
                categoria = existente
            } else if deveInserir(id: categoriaSeed.id, versao: categoriaSeed.introduzidoNaVersao) {
                let (r, g, b) = categoriaSeed.cor.toRGBComponents()
                categoria = CategoriaModel(
                    id: categoriaSeed.id,
                    nome: AppLocalization.string(categoriaSeed.nome, locale: locale),
                    icon: categoriaSeed.icon,
                    red: r,
                    green: g,
                    blue: b
                )
                categoria.atualizadoEm = .distantPast
                context.insert(categoria)
                categoriaCriadaAgora = true
                houveAlteracao = true
            } else {
                continue
            }

            var subcategoriasInseridas = 0
            for subSeed in categoriaSeed.subcategorias
            where !subcategoriaIDs.contains(subSeed.id) && deveInserir(id: subSeed.id, versao: subSeed.introduzidoNaVersao) {
                let novaSub = SubcategoriaModel(
                    id: subSeed.id,
                    nome: AppLocalization.string(subSeed.nome, locale: locale),
                    icon: subSeed.icon,
                    categoria: categoria
                )
                novaSub.atualizadoEm = .distantPast
                context.insert(novaSub)
                subcategoriasInseridas += 1
                houveAlteracao = true
            }

            // RN-08: a Renda nova nunca nasce sem subcategoria, mesmo que a lápide tenha apagado todas as do seed.
            if categoriaCriadaAgora && categoriaSeed.id == SeedIDs.idRenda && subcategoriasInseridas == 0,
               let geral = categoriaSeed.subcategorias.first(where: { $0.id == SeedIDs.idSubRendaGeral }) {
                let subGeral = SubcategoriaModel(
                    id: geral.id,
                    nome: AppLocalization.string(geral.nome, locale: locale),
                    icon: geral.icon,
                    categoria: categoria
                )
                subGeral.atualizadoEm = .distantPast
                context.insert(subGeral)
            }
        }

        if houveAlteracao {
            try context.save()
        }
        settings.seedVersaoAplicada = SeedCatalogo.versao
    }

    /// Store com dados e sem versão gravada é de quem veio da 1.5, que já tinha o catálogo da versão 1.
    private func versaoJaAplicada(storeVazio: Bool) -> Int {
        storeVazio ? 0 : max(settings.seedVersaoAplicada, 1)
    }
}
