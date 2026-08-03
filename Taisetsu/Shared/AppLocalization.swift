import Foundation

enum AppLocalization {
    private final class BundleToken {}

    static var bundle: Bundle { Bundle(for: BundleToken.self) }

    static func string(_ key: String, locale: Locale = .current) -> String {
        let requestedLanguage = locale.language.languageCode?.identifier
        let matchingLocalizations = bundle.localizations.filter {
            Locale.Language(identifier: $0).languageCode?.identifier == requestedLanguage
        }
        guard
            let localization = Bundle.preferredLocalizations(
                from: matchingLocalizations,
                forPreferences: [locale.identifier]
            ).first,
            let path = bundle.path(forResource: localization, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else { return key }
        return localizedBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg..., locale: Locale = .current) -> String {
        String(format: string(key, locale: locale), locale: locale, arguments: arguments)
    }

    static func list(_ values: [String], locale: Locale = .current) -> String {
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: values) ?? values.joined(separator: ", ")
    }
}

enum LocalizedCalendarLayout {
    static func weekdaySymbols(for calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let startIndex = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
}
