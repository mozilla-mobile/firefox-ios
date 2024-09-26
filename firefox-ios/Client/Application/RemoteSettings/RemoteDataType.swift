// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum RemoteDataTypeError: Error, LocalizedError {
    case fileNotFound(fileName: String)
    case decodingError(fileName: String, error: Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "The file '\(fileName)' was not found in the app bundle."
        case .decodingError(let fileName, let error):
            return "Failed to decode '\(fileName)' with \(error.localizedDescription)"
        }
    }
}

enum RemoteDataType: String, Codable {
    case passwordRules

    var type: RemoteDataTypeRecord.Type {
        switch self {
        case .passwordRules:
            return PasswordRuleRecord.self
        }
    }

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

    func loadLocalSettingsFromJSON<T: RemoteDataTypeRecord>() async throws -> T {
        let fileName = self.fileName

        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            throw RemoteDataTypeError.fileNotFound(fileName: fileName)
        }

        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            throw RemoteDataTypeError.decodingError(fileName: fileName, error: error)
        }
    }
}
