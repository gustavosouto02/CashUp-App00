import Foundation

/// Formatador único de moeda para todo o app, respeitando a moeda e localidade do usuário.
enum BRLCurrencyFormatter {
    static var effectiveLocale: Locale {
        let current = Locale.autoupdatingCurrent
        let lang = current.language.languageCode?.identifier ?? "pt"
        if lang == "en" && (current.region == nil || current.region?.identifier == "BR") {
            return Locale(identifier: "en_US")
        } else if lang == "es" && (current.region == nil || current.region?.identifier == "BR") {
            return Locale(identifier: "es_ES")
        }
        return current
    }

    private static let cache = NSCache<NSString, NumberFormatter>()

    static func string(from value: Double, locale: Locale? = nil) -> String {
        let loc = locale ?? effectiveLocale
        let key = loc.identifier as NSString

        let formatter: NumberFormatter
        if let cached = cache.object(forKey: key) {
            formatter = cached
        } else {
            let newFormatter = NumberFormatter()
            newFormatter.numberStyle = .currency
            newFormatter.locale = loc
            cache.setObject(newFormatter, forKey: key)
            formatter = newFormatter
        }

        return formatter.string(from: NSNumber(value: value)) ?? "0,00"
    }
}

/// Utilitário central de localização para resolver strings respeitando o Locale/idioma fornecido.
enum AppLocalization {
    static var resourceBundle: Bundle {
        if Bundle.main.path(forResource: "pt-BR", ofType: "lproj") != nil {
            return Bundle.main
        }
        for bundle in Bundle.allBundles {
            if bundle.path(forResource: "pt-BR", ofType: "lproj") != nil {
                return bundle
            }
        }
        return Bundle.main
    }

    static func string(
        _ key: String,
        locale: Locale = .autoupdatingCurrent,
        bundle: Bundle? = nil
    ) -> String {
        let targetBundle = bundle ?? resourceBundle
        let languageCode = (locale.language.languageCode?.identifier ?? locale.identifier).lowercased()

        let langResource: String
        if languageCode.hasPrefix("pt") {
            langResource = "pt-BR"
        } else if languageCode.hasPrefix("es") {
            langResource = "es"
        } else {
            langResource = "en"
        }

        if let path = targetBundle.path(forResource: langResource, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return langBundle.localizedString(forKey: key, value: key, table: nil)
        }

        return targetBundle.localizedString(forKey: key, value: key, table: nil)
    }
}
