import Foundation

/// Mês e ano por extenso, com a primeira letra maiúscula, no idioma do usuário.
///
/// Em pt-BR mantém o padrão histórico do app ("Outubro 2026", sem o "de" do CLDR); nos demais idiomas
/// usa o template localizado (en: "October 2026", es: "Octubre de 2026").
enum MonthYearFormatter {
    static func string(from date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        if locale.language.languageCode?.identifier == "pt" {
            formatter.dateFormat = "MMMM yyyy"
        } else {
            formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        }
        let texto = formatter.string(from: date)
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }
}
