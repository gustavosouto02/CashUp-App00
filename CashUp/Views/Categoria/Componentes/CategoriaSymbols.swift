import Foundation

struct CategoriaSymbolGroup: Identifiable {
    let id: String
    let titulo: String
    let simbolos: [String]
}

enum CategoriaSymbols {
    static let padrao: String = "tag.fill"

    static let grupos: [CategoriaSymbolGroup] = [
        CategoriaSymbolGroup(
            id: "compras",
            titulo: "Compras & Mercado",
            simbolos: [
                "cart.fill", "bag.fill", "tag.fill", "gift.fill",
                "basket.fill", "creditcard.fill", "tshirt.fill", "barcode"
            ]
        ),
        CategoriaSymbolGroup(
            id: "casa",
            titulo: "Casa & Família",
            simbolos: [
                "house.fill", "sofa.fill", "lightbulb.fill", "wrench.and.screwdriver.fill",
                "drop.fill", "bolt.fill", "pawprint.fill", "bed.double.fill"
            ]
        ),
        CategoriaSymbolGroup(
            id: "alimentacao",
            titulo: "Alimentação",
            simbolos: [
                "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "takeoutbag.and.cup.and.straw.fill",
                "birthday.cake.fill", "carrot.fill", "fish.fill", "mug.fill"
            ]
        ),
        CategoriaSymbolGroup(
            id: "transporte",
            titulo: "Transporte & Viagens",
            simbolos: [
                "car.fill", "fuelpump.fill", "bus.fill", "tram.fill",
                "airplane", "bicycle", "figure.walk", "sailboat.fill"
            ]
        ),
        CategoriaSymbolGroup(
            id: "saude",
            titulo: "Saúde & Cuidados",
            simbolos: [
                "heart.fill", "cross.case.fill", "pills.fill", "stethoscope",
                "dumbbell.fill", "figure.run", "mouth.fill", "eyeglasses"
            ]
        ),
        CategoriaSymbolGroup(
            id: "trabalho",
            titulo: "Trabalho & Estudos",
            simbolos: [
                "briefcase.fill", "graduationcap.fill", "book.closed.fill", "folder.fill",
                "laptopcomputer", "building.2.fill", "newspaper.fill", "signature"
            ]
        ),
        CategoriaSymbolGroup(
            id: "lazer",
            titulo: "Lazer & Cultura",
            simbolos: [
                "gamecontroller.fill", "movieclapper.fill", "tv.fill", "music.note",
                "camera.fill", "theatermasks.fill", "paintpalette.fill", "ticket.fill"
            ]
        ),
        CategoriaSymbolGroup(
            id: "financas",
            titulo: "Finanças & Metas",
            simbolos: [
                "banknote.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis", "building.columns.fill",
                "shield.fill", "lock.fill", "percent", "safe"
            ]
        )
    ]

    static var todos: [String] {
        grupos.flatMap(\.simbolos)
    }
}
