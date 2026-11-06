import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        let template = Bundle.main.localizedString(forKey: key, value: key, table: nil)
        return String(format: template, locale: Locale.current, arguments: args)
    }
}
