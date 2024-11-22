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
    case contentBlockingLists

    var type: any RemoteDataTypeRecord.Type {
        switch self {
        case .passwordRules:
            return PasswordRuleRecord.self
        case .contentBlockingLists:
            return ContentBlockingListRecord.self
        }
    }

    var fileNames: [String] {
        switch self {
        case .passwordRules:
            return ["RemotePasswordRules"]
        case .contentBlockingLists:
            return BlocklistFileName.allCases.map { $0.filename }
        }
    }

    var name: String {
        switch self {
        case .passwordRules:
            return "Password Rules"
        case .contentBlockingLists:
            return "Content Blocking Lists"
        }
    }

    /// Loads the local settings for the given data type record, returning the
    /// decoded objects.
    /// - Returns: settings decoded to their RemoteDataTypeRecord.
    func loadLocalSettingsFromJSON<T: RemoteDataTypeRecord>() async throws -> [T] {
        guard let fileName = self.fileNames.first else {
            assertionFailure("No filename available for setting type.")
            throw RemoteDataTypeError.fileNotFound(fileName: "")
        }

        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            throw RemoteDataTypeError.fileNotFound(fileName: fileName)
        }

        let url = URL(fileURLWithPath: path)

        do {
            let data = try Data(contentsOf: url)

            if let decodedArray = try? JSONDecoder().decode([T].self, from: data) {
                return decodedArray
            }
            let singleObject = try JSONDecoder().decode(T.self, from: data)
            return [singleObject]
        } catch {
            throw RemoteDataTypeError.decodingError(fileName: fileName, error: error)
        }
    }

    /// Loads the local settings JSON for the given setting file.
    /// - Returns: the raw JSON file data.
    func loadLocalSettingsFileAsJSON(fileName: String) throws -> Data {
        guard fileNames.contains(fileName) else {
            throw RemoteDataTypeError.fileNotFound(fileName: fileName)
        }

        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
            throw RemoteDataTypeError.fileNotFound(fileName: fileName)
        }

        let url = URL(fileURLWithPath: path)

        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            throw RemoteDataTypeError.decodingError(fileName: fileName, error: error)
        }
    }
}
