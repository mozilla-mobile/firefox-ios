// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Language: String, Codable, CaseIterable {
    case
    de,
    en,
    es,
    it,
    fr,
    nl,
    sv

    public internal(set) static var current = make(for: .current)

    var locale: Local {
        switch self {
        case .de: return .de_de
        case .en: return .en_us
        case .es: return .es_es
        case .it: return .it_it
        case .fr: return .fr_fr
        case .nl: return .nl_nl
        case .sv: return .sv_se
        }
    }

    private static let queue = DispatchQueue(label: "\(Bundle.ecosia.bundleIdentifier!).LanguageQueue")
    static func make(for locale: Locale) -> Self {
        return queue.sync {
            locale.withLanguage ?? .en
        }
    }
}

private extension Locale {
    var withLanguage: Ecosia.Language? {
        languageCode.flatMap {
            Ecosia.Language(rawValue: $0.lowercased())
        }
    }
}
