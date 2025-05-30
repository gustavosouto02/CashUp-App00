import SwiftUI

// MARK: - View do ícone com fundo em círculo
struct CategoriasViewIcon: View {
    let systemName: String
    let cor: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(cor) // cor sólida, sem transparência
                .frame(width: size * 1.4, height: size * 1.4)
            Image(systemName: systemName)
                .font(.system(size: size * 0.6))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    CategoriasViewIcon(systemName: "dollarsign.bank.building.fill", cor: .red, size: 24)
}

// MARK: - Subcategoria
struct Subcategoria: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let nome: String
    let icon: String

    // Agora id pode ser passado manualmente (para reutilizar)
    init(id: UUID = UUID(), nome: String, icon: String) {
        self.id = id
        self.nome = nome
        self.icon = icon
    }
}

// MARK: - Categoria
struct Categoria: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let nome: String
    let cor: CodableColor
    let icon: String
    let subcategorias: [Subcategoria]

    var color: Color { cor.color }

    // Também aceita id opcional para reutilizar
    init(id: UUID = UUID(), nome: String, cor: Color, icon: String, subcategorias: [Subcategoria]) {
        self.id = id
        self.nome = nome
        self.cor = CodableColor(color: cor)
        self.icon = icon
        self.subcategorias = subcategorias
    }
}

// MARK: - CodableColor para codificar/descodificar Color
struct CodableColor: Codable, Equatable, Hashable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        self.red = r
        self.green = g
        self.blue = b
    }
}

// MARK: - CategoriasData (Mock)
struct CategoriasData {
    // Definindo IDs fixos para categorias e subcategorias
    // ATENÇÃO: Se você já tem dados salvos, esses UUIDs precisam corresponder
    // aos UUIDs que foram gerados e salvos para as categorias/subcategorias
    // existentes no seu app. Caso contrário, você pode precisar "migrar" seus dados.

    // MUITO IMPORTANTE: MUDANÇA AQUI!
    // Usando '?? UUID()' para evitar crash se a string do UUID for inválida.
    // O erro na linha 93 É MUITO PROVÁVEL QUE ESTEJA EM UMA DESSAS LINHAS ABAIXO
    // OU NA LINHA 153 (Subcategoria de "Renda").
    static let idRenda = UUID(uuidString: "A0A0A0A0-A0A0-A0A0-A0A0-A0A0A0A0A0A0") ?? UUID()
    static let idEntretenimento = UUID(uuidString: "B1B1B1B1-B1B1-B1B1-B1B1-B1B1B1B1B1B1") ?? UUID()
    static let idDiversos = UUID(uuidString: "C2C2C2C2-C2C2-C2C2-C2C2-C2C2C2C2C2C2") ?? UUID()
    static let idComidasEBebidas = UUID(uuidString: "D3D3D3D3-D3D3-D3D3-D3D3-D3D3D3D3D3D3") ?? UUID()
    static let idHabitacao = UUID(uuidString: "E4E4E4E4-E4E4-E4E4-E4E4-E4E4E4E4E4E4") ?? UUID()
    static let idTransporte = UUID(uuidString: "F5F5F5F5-F5F5-F5F5-F5F5-F5F5F5F5F5F5") ?? UUID()
    static let idEstiloDeVida = UUID(uuidString: "G6G6G6G6-G6G6-G6G6-G6G6-G6G6G6G6G6G6") ?? UUID()

    // Subcategorias específicas
    static let idAcademia = UUID(uuidString: "B6C7D8E9-F0A1-2B3C-4D5E-6F7A8B9C0D1E") ?? UUID()
    static let idRendaSub = UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID() // Usado na subcategoria "Renda" lá embaixo

    static let todas: [Categoria] = [
        Categoria(
            id: idDiversos, // Usando ID fixo
            nome: "Diversos",
            cor: Color(red: 0.65, green: 0.45, blue: 0.25),
            icon: "puzzlepiece",
            subcategorias: [
                Subcategoria(nome: "Custos Bancários", icon: "dollarsign.bank.building.fill"),
                Subcategoria(nome: "Desconhecido", icon: "questionmark.app.fill"),
                Subcategoria(nome: "Diversos", icon: "archivebox.fill"),
                Subcategoria(nome: "Roupas", icon: "tshirt"),
                Subcategoria(nome: "Saúde", icon: "heart.fill")
            ]
        ),
        Categoria(
            id: idEntretenimento, // Usando ID fixo
            nome: "Entretenimento",
            cor: Color(red: 1.0, green: 0.39, blue: 0.51),
            icon: "gamecontroller",
            subcategorias: [
                Subcategoria(id: idAcademia, nome: "Academia", icon: "dumbbell.fill"), // Usando ID fixo
                Subcategoria(nome: "Assinatura", icon: "rectangle.stack.badge.play.fill"),
                Subcategoria(nome: "Boate", icon: "party.popper.fill"),
                Subcategoria(nome: "Boliche", icon: "figure.bowling"),
                Subcategoria(nome: "Cinema", icon: "movieclapper.fill"),
                Subcategoria(nome: "Clube", icon: "beach.umbrella.fill"),
                Subcategoria(nome: "Eletrônicos", icon: "ipad"),
                Subcategoria(nome: "Entretenimento", icon: "gamecontroller"),
                Subcategoria(nome: "Esportes", icon: "soccerball.inverse"),
                Subcategoria(nome: "Férias", icon: "airplane.departure"),
                Subcategoria(nome: "Passatempo", icon: "book.fill"),
                Subcategoria(nome: "Show", icon: "music.microphone")
            ]
        ),
        Categoria(
            id: idComidasEBebidas, // Usando ID fixo
            nome: "Comidas e Bebidas",
            cor: .teal,
            icon: "fork.knife",
            subcategorias: [
                Subcategoria(nome: "Bebidas", icon: "wineglass.fill"),
                Subcategoria(nome: "Café", icon: "cup.and.heat.waves.fill"),
                Subcategoria(nome: "Comida", icon: "carrot.fill"),
                Subcategoria(nome: "Doce", icon: "birthday.cake"),
                Subcategoria(nome: "FastFood", icon: "takeoutbag.and.cup.and.straw"),
                Subcategoria(nome: "Mantimentos", icon: "cart.fill"),
                Subcategoria(nome: "Restaurante", icon: "fork.knife.circle")
            ]
        ),
        Categoria(
            id: idHabitacao, // Usando ID fixo
            nome: "Habitação",
            cor: .orange,
            icon: "house",
            subcategorias: [
                Subcategoria(nome: "Aluguel", icon: "house.fill"),
                Subcategoria(nome: "Artigos para o lar", icon: "sofa.fill"),
                Subcategoria(nome: "Água", icon: "drop"),
                Subcategoria(nome: "Banco", icon: "building.columns"),
                Subcategoria(nome: "Contas", icon: "doc.plaintext"),
                Subcategoria(nome: "Eletricidade", icon: "bolt.fill"),
                Subcategoria(nome: "Financiamento", icon: "creditcard"),
                Subcategoria(nome: "Habitação", icon: "house.lodge.fill"),
                Subcategoria(nome: "Impostos", icon: "percent"),
                Subcategoria(nome: "Jardim", icon: "leaf"),
                Subcategoria(nome: "Internet", icon: "wifi"),
                Subcategoria(nome: "Manutenção", icon: "wrench.and.screwdriver"),
                Subcategoria(nome: "Serviço", icon: "person.2.badge.gearshape.fill"),
                Subcategoria(nome: "Seguro", icon: "shield"),
                Subcategoria(nome: "Telefone", icon: "phone.fill"),
                Subcategoria(nome: "TV", icon: "tv.fill")
            ]
        ),
        Categoria(
            id: idTransporte, // Usando ID fixo
            nome: "Transporte",
            cor: Color(red: 0.75, green: 0.35, blue: 0.98),
            icon: "car",
            subcategorias: [
                Subcategoria(nome: "Carros de Aplicativo", icon: "car.2.fill"),
                Subcategoria(nome: "Custos do Carro", icon: "car.circle.fill"),
                Subcategoria(nome: "Estacionamento", icon: "parkingsign.circle.fill"),
                Subcategoria(nome: "Financiamento", icon: "creditcard"),
                Subcategoria(nome: "Gasolina", icon: "fuelpump.fill"),
                Subcategoria(nome: "Manutenção", icon: "car.badge.gearshape.fill"),
                Subcategoria(nome: "Seguro do Carro", icon: "car.side.lock.fill"),
                Subcategoria(nome: "Transporte Público", icon: "bus"),
                Subcategoria(nome: "Transporte", icon: "tram"),
                Subcategoria(nome: "Táxi", icon: "car.top.arrowtriangle.rear.left")
            ]
        ),
        Categoria(
            id: idEstiloDeVida, // Usando ID fixo
            nome: "Estilo de Vida",
            cor: Color(red: 0.85, green: 0.33, blue: 0.31),
            icon: "figure.wave",
            subcategorias: [
                Subcategoria(nome: "Animal Estimação", icon: "pawprint.fill"),
                Subcategoria(nome: "Caridade", icon: "hands.clap.fill"),
                Subcategoria(nome: "Compras", icon: "bag.fill"),
                Subcategoria(nome: "Comunidade", icon: "person.3.fill"),
                Subcategoria(nome: "Creche", icon: "figure.and.child.holdinghands"),
                Subcategoria(nome: "Dentista", icon: "cross.case"),
                Subcategoria(nome: "Escritório", icon: "folder.fill"),
                Subcategoria(nome: "Educação", icon: "book.closed.fill"),
                Subcategoria(nome: "Estilo de Vida", icon: "figure.dance"),
                Subcategoria(nome: "Farmácia", icon: "pills.fill"),
                Subcategoria(nome: "Hotel", icon: "bed.double.fill"),
                Subcategoria(nome: "Médico", icon: "stethoscope.circle.fill"),
                Subcategoria(nome: "Presente", icon: "gift.fill"),
                Subcategoria(nome: "Trabalho", icon: "briefcase.fill"),
                Subcategoria(nome: "Viagem", icon: "airplane")
            ]
        ),
        Categoria(
            id: idRenda, // Usando ID fixo
            nome: "Renda",
            cor: Color(hue: 135/360, saturation: 0.8, brightness: 0.7),
            icon: "dollarsign",
            subcategorias: [
                Subcategoria(nome: "Investimentos", icon: "chart.line.uptrend.xyaxis"),
                Subcategoria(nome: "Juros", icon: "percent"),
                Subcategoria(nome: "Pensão", icon: "person.2.fill"),
                // MUITO IMPORTANTE: MUDANÇA AQUI!
                // A linha 93 no seu Xcode pode ser esta Subcategoria se a contagem variar.
                Subcategoria(id: UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID(), nome: "Renda", icon: "arrow.down.to.line.circle.fill"),
                Subcategoria(nome: "Salário", icon: "banknote"),
                Subcategoria(nome: "Salário Família", icon: "house.and.flag.fill")
            ]
        )
    ]

    // Funções auxiliares para buscar por ID
    static func categoria(for id: UUID) -> Categoria? {
        return todas.first(where: { $0.id == id })
    }

    static func subcategoria(for id: UUID) -> Subcategoria? {
        for categoria in todas {
            if let sub = categoria.subcategorias.first(where: { $0.id == id }) {
                return sub
            }
        }
        return nil
    }

    static func categoriasub(for subcategoriaID: UUID) -> Categoria? {
        for categoria in todas {
            if categoria.subcategorias.contains(where: { $0.id == subcategoriaID }) {
                return categoria
            }
        }
        return nil
    }
}
