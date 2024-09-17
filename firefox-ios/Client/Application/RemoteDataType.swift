// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum RemoteDataType {
    case passwordRules

    var fileName: String {
        switch self {
        case .passwordRules:
            return "RemotePasswordRules"
        }
    }

    var name: String {
        switch self {
        case .passwordRules:
            return "Password Rules"
        }
    }

    static func loadJSON<T: Codable>(fileName: String, type: T.Type) -> T? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else { return nil }
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            return nil
        }
    }

    static func loadRecord<T: Codable>(for rule: RemoteSettingsFetchConfig.Rule, type: T.Type) -> T? {
        let fileName = rule.file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
        switch fileName {
        case RemoteDataType.passwordRules.fileName:
            return loadJSON(fileName: fileName, type: type)
            // NOTE: Add cases for other files (ex. search config v2)
        default:
            return nil
        }
    }
}
