//
//  SeedData.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftData
import SwiftUI

fileprivate struct CategoriaSeedInfo {
    let id: UUID
    let nome: String
    let cor: Color
    let icon: String
    let subcategorias: [SubcategoriaSeedInfo]
}

fileprivate struct SubcategoriaSeedInfo {
    let id: UUID
    let nome: String
    let icon: String
}

struct SeedIDs {
    static let idRenda           = UUID(uuidString: "A0A0A0A0-A0A0-A0A0-A0A0-A0A0A0A0A0A0")!
    static let idEntretenimento  = UUID(uuidString: "B1B1B1B1-B1B1-B1B1-B1B1-B1B1B1B1B1B1")!
    static let idDiversos        = UUID(uuidString: "C2C2C2C2-C2C2-C2C2-C2C2-C2C2C2C2C2C2")!
    static let idComidasEBebidas = UUID(uuidString: "D3D3D3D3-D3D3-D3D3-D3D3-D3D3D3D3D3D3")!
    static let idHabitacao       = UUID(uuidString: "E4E4E4E4-E4E4-E4E4-E4E4-E4E4E4E4E4E4")!
    static let idTransporte      = UUID(uuidString: "F5F5F5F5-F5F5-F5F5-F5F5-F5F5F5F5F5F5")!
    static let idEstiloDeVida    = UUID(uuidString: "A6A6A6A6-A6A6-A6A6-A6A6-A6A6A6A6A6A6")!

    // Subcategorias
    static let idSubCustosBancarios     = UUID(uuidString: "00010001-0001-0001-0001-000100010001")!
    static let idSubDesconhecido        = UUID(uuidString: "00020002-0002-0002-0002-000200020002")!
    static let idSubDiversosGerais      = UUID(uuidString: "00030003-0003-0003-0003-000300030003")!
    static let idSubRoupas              = UUID(uuidString: "00040004-0004-0004-0004-000400040004")!
    static let idSubSaude               = UUID(uuidString: "00050005-0005-0005-0005-000500050005")!
    
    static let idSubAcademia            = UUID(uuidString: "B6C7D8E9-F0A1-2B3C-4D5E-6F7A8B9C0D1E")!
    static let idSubAssinatura          = UUID(uuidString: "00070007-0007-0007-0007-000700070007")!
    static let idSubBoate               = UUID(uuidString: "B1B6A0CA-8A63-4630-8C0B-D8029163CA03")!
    static let idSubBoliche             = UUID(uuidString: "00090009-0009-0009-0009-000900090009")!
    static let idSubCinema              = UUID(uuidString: "000A000A-000A-000A-000A-000A000A000A")!
    static let idSubClube               = UUID(uuidString: "000B000B-000B-000B-000B-000B000B000B")!
    static let idSubEletronicos         = UUID(uuidString: "000C000C-000C-000C-000C-000C000C000C")!
    static let idSubEntretenimentoGeral = UUID(uuidString: "000D000D-000D-000D-000D-000D000D000D")!
    static let idSubEsportes            = UUID(uuidString: "000E000E-000E-000E-000E-000E000E000E")!
    static let idSubFerias              = UUID(uuidString: "000F000F-000F-000F-000F-000F000F000F")!
    static let idSubPassatempo          = UUID(uuidString: "00100010-0010-0010-0010-001000100010")!
    static let idSubShow                = UUID(uuidString: "00110011-0011-0011-0011-001100110011")!

    static let idSubBebidas             = UUID(uuidString: "00120012-0012-0012-0012-001200120012")!
    static let idSubCafe                = UUID(uuidString: "00130013-0013-0013-0013-001300130013")!
    static let idSubComida              = UUID(uuidString: "00140014-0014-0014-0014-001400140014")!
    static let idSubDoce                = UUID(uuidString: "00150015-0015-0015-0015-001500150015")!
    static let idSubFastFood            = UUID(uuidString: "00160016-0016-0016-0016-001600160016")!
    static let idSubMantimentos         = UUID(uuidString: "00170017-0017-0017-0017-001700170017")!
    static let idSubRestaurante         = UUID(uuidString: "00180018-0018-0018-0018-001800180018")!

    static let idSubAluguel             = UUID(uuidString: "00190019-0019-0019-0019-001900190019")!
    static let idSubArtigosLar          = UUID(uuidString: "001A001A-001A-001A-001A-001A001A001A")!
    static let idSubAgua                = UUID(uuidString: "001B001B-001B-001B-001B-001B001B001B")!
    static let idSubBanco               = UUID(uuidString: "001C001C-001C-001C-001C-001C001C001C")!
    static let idSubContas              = UUID(uuidString: "001D001D-001D-001D-001D-001D001D001D")!
    static let idSubEletricidade        = UUID(uuidString: "001E001E-001E-001E-001E-001E001E001E")!
    static let idSubFinanciamentoHab    = UUID(uuidString: "001F001F-001F-001F-001F-001F001F001F")!
    static let idSubHabitacaoGeral      = UUID(uuidString: "00200020-0020-0020-0020-002000200020")!
    static let idSubImpostos            = UUID(uuidString: "00210021-0021-0021-0021-002100210021")!
    static let idSubJardim              = UUID(uuidString: "00220022-0022-0022-0022-002200220022")!
    static let idSubInternet            = UUID(uuidString: "00230023-0023-0023-0023-002300230023")!
    static let idSubManutencaoHab       = UUID(uuidString: "00240024-0024-0024-0024-002400240024")!
    static let idSubServico             = UUID(uuidString: "00250025-0025-0025-0025-002500250025")!
    static let idSubSeguroHab           = UUID(uuidString: "00260026-0026-0026-0026-002600260026")!
    static let idSubTelefone            = UUID(uuidString: "00270027-0027-0027-0027-002700270027")!
    static let idSubTV                  = UUID(uuidString: "00280028-0028-0028-0028-002800280028")!

    static let idSubCarrosAplicativo    = UUID(uuidString: "00290029-0029-0029-0029-002900290029")!
    static let idSubCustosCarro         = UUID(uuidString: "002A002A-002A-002A-002A-002A002A002A")!
    static let idSubEstacionamento      = UUID(uuidString: "002B002B-002B-002B-002B-002B002B002B")!
    static let idSubFinanciamentoTrans  = UUID(uuidString: "002C002C-002C-002C-002C-002C002C002C")!
    static let idSubGasolina            = UUID(uuidString: "002D002D-002D-002D-002D-002D002D002D")!
    static let idSubManutencaoTrans     = UUID(uuidString: "002E002E-002E-002E-002E-002E002E002E")!
    static let idSubSeguroCarro         = UUID(uuidString: "002F002F-002F-002F-002F-002F002F002F")!
    static let idSubTransportePublico   = UUID(uuidString: "00300030-0030-0030-0030-003000300030")!
    static let idSubTransporteGeral     = UUID(uuidString: "00310031-0031-0031-0031-003100310031")!
    static let idSubTaxi                = UUID(uuidString: "00320032-0032-0032-0032-003200320032")!
    static let idSubAnimalEstimacao     = UUID(uuidString: "00330033-0033-0033-0033-003300330033")!
    static let idSubCaridade            = UUID(uuidString: "00340034-0034-0034-0034-003400340034")!
    static let idSubCompras             = UUID(uuidString: "00350035-0035-0035-0035-003500350035")!
    static let idSubComunidade          = UUID(uuidString: "00360036-0036-0036-0036-003600360036")!
    static let idSubCreche              = UUID(uuidString: "00370037-0037-0037-0037-003700370037")!
    static let idSubDentista            = UUID(uuidString: "00380038-0038-0038-0038-003800380038")!
    static let idSubEscritorio          = UUID(uuidString: "00390039-0039-0039-0039-003900390039")!
    static let idSubEducacao            = UUID(uuidString: "003A003A-003A-003A-003A-003A003A003A")!
    static let idSubEstiloVidaGeral     = UUID(uuidString: "003B003B-003B-003B-003B-003B003B003B")!
    static let idSubFarmacia            = UUID(uuidString: "003C003C-003C-003C-003C-003C003C003C")!
    static let idSubHotel               = UUID(uuidString: "003D003D-003D-003D-003D-003D003D003D")!
    static let idSubMedico              = UUID(uuidString: "003E003E-003E-003E-003E-003E003E003E")!
    static let idSubPresente            = UUID(uuidString: "003F003F-003F-003F-003F-003F003F003F")!
    static let idSubTrabalho            = UUID(uuidString: "00400040-0040-0040-0040-004000400040")!
    static let idSubViagem              = UUID(uuidString: "00410041-0041-0041-0041-004100410041")!
    static let idSubInvestimentos       = UUID(uuidString: "00420042-0042-0042-0042-004200420042")!
    static let idSubJuros               = UUID(uuidString: "00430043-0043-0043-0043-004300430043")!
    static let idSubPensao              = UUID(uuidString: "00440044-0044-0044-0044-004400440044")!
    static let idSubRendaGeral          = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    static let idSubSalario             = UUID(uuidString: "00460046-0046-0046-0046-004600460046")!
    static let idSubSalarioFamilia      = UUID(uuidString: "00470047-0047-0047-0047-004700470047")!
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

fileprivate let todasCategoriasSeedInfo: [CategoriaSeedInfo] = [
    CategoriaSeedInfo(
        id: SeedIDs.idDiversos,
        nome: "Diversos",
        cor: Color(red: 0.35, green: 0.2, blue: 0.1),
        icon: "puzzlepiece",
        subcategorias: [
            SubcategoriaSeedInfo(id: SeedIDs.idSubCustosBancarios, nome: "Custos Bancários", icon: "dollarsign.bank.building.fill"),
            SubcategoriaSeedInfo(id: SeedIDs.idSubDesconhecido, nome: "Desconhecido", icon: "questionmark.app.fill"),
            SubcategoriaSeedInfo(id: SeedIDs.idSubDiversosGerais, nome: "Diversos", icon: "archivebox.fill"),
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

@MainActor
func popularDadosIniciaisSeNecessario(modelContext: ModelContext) async {
    do {
        let categoriasExistentes = try modelContext.fetch(FetchDescriptor<CategoriaModel>())
        let subcategoriasExistentes = try modelContext.fetch(FetchDescriptor<SubcategoriaModel>())

        let categoriaIDsExistentes = Set(categoriasExistentes.map { $0.id })
        let subcategoriaIDsExistentes = Set(subcategoriasExistentes.map { $0.id })


        var novasCategorias: [CategoriaModel] = []

        for categoriaSeed in todasCategoriasSeedInfo {
            guard !categoriaIDsExistentes.contains(categoriaSeed.id) else {
//                print("Categoria já existe: \(categoriaSeed.nome)")
                continue
            }
            let (r, g, b) = categoriaSeed.cor.toRGBComponents()

            let novaCategoria = CategoriaModel(
                id: categoriaSeed.id,
                nome: categoriaSeed.nome,
                icon: categoriaSeed.icon,
                red: r,
                green: g,
                blue: b
            )

            var novasSubcategorias: [SubcategoriaModel] = []

            for subSeed in categoriaSeed.subcategorias {
                guard !subcategoriaIDsExistentes.contains(subSeed.id) else {
//                    print("Subcategoria já existe: \(subSeed.nome)")
                    continue
                }

                let novaSub = SubcategoriaModel(
                    id: subSeed.id,
                    nome: subSeed.nome,
                    icon: subSeed.icon,
                    categoria: novaCategoria
                )
                novasSubcategorias.append(novaSub)
            }

            novaCategoria.subcategorias = novasSubcategorias
            novasCategorias.append(novaCategoria)
        }

        for categoria in novasCategorias {
            modelContext.insert(categoria)
        }

        if !novasCategorias.isEmpty {
            try modelContext.save()
        } else {
        }
    } catch {
        print("❌ Erro ao popular dados iniciais: \(error.localizedDescription)")
    }
    do {
        // Busca IDs existentes para evitar conflitos com .unique
        let categoriasExistentes = try modelContext.fetch(FetchDescriptor<CategoriaModel>())
        let subcategoriasExistentes = try modelContext.fetch(FetchDescriptor<SubcategoriaModel>())

        let categoriaIDsExistentes = Set(categoriasExistentes.map(\.id))
        let subcategoriaIDsExistentes = Set(subcategoriasExistentes.map(\.id))

        var novasCategorias: [CategoriaModel] = []

        for categoriaSeed in todasCategoriasSeedInfo {
            guard !categoriaIDsExistentes.contains(categoriaSeed.id) else {
                continue
            }

            let (r, g, b) = categoriaSeed.cor.toRGBComponents()

            let novaCategoria = CategoriaModel(
                id: categoriaSeed.id,
                nome: categoriaSeed.nome,
                icon: categoriaSeed.icon,
                red: r,
                green: g,
                blue: b
            )


            var novasSubcategorias: [SubcategoriaModel] = []

            for subSeed in categoriaSeed.subcategorias {
                guard !subcategoriaIDsExistentes.contains(subSeed.id) else {
//                    print("Subcategoria já existe: \(subSeed.nome)")
                    continue
                }

                let novaSub = SubcategoriaModel(
                    id: subSeed.id,
                    nome: subSeed.nome,
                    icon: subSeed.icon,
                    categoria: novaCategoria
                )
                novasSubcategorias.append(novaSub)
            }

            novaCategoria.subcategorias = novasSubcategorias
            novasCategorias.append(novaCategoria)
        }

        for categoria in novasCategorias {
            modelContext.insert(categoria)
        }

        if !novasCategorias.isEmpty {
            try modelContext.save()
            print(" Dados iniciais de categoria populados com sucesso.")
        } else {
        }
    } catch {
        print(" Erro ao popular dados iniciais: \(error.localizedDescription)")
    }
}
