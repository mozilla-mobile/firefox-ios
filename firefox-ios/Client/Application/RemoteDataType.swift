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

    // Method to load local settings from a JSON file
//    func loadLocalSettingsFromJSON<T: RemoteDataTypeRecord>(for type: RemoteDataType) -> T? {
//        // Get the filename and the expected type from RemoteDataType
//        let fileName = type.fileName
//        let recordType = type.type
//        
//        // Locate the JSON file in the bundle
//        guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
//            print("Failed to find file: \(fileName).json in the bundle.")
//            return nil
//        }
//        
//        // Load the data from the file
//        let url = URL(fileURLWithPath: path)
//        do {
//            let data = try Data(contentsOf: url)
//            let decodedObject = try JSONDecoder().decode(T.self, from: data)
//            return decodedObject
//        } catch {
//            print("Failed to decode JSON file: \(fileName).json, error: \(error.localizedDescription)")
//            return nil
//        }
//    }
//
//    private func loadLocalSettingsFromJSON<T: Codable>(name fileName: String,
//                                                       of type: T.Type) -> T? {
//        guard let path = Bundle.main.path(forResource: fileName,
//                                          ofType: "json") else { return nil }
//        let url = URL(fileURLWithPath: path)
//        do {
//            let data = try Data(contentsOf: url)
//            let decodedObject = try JSONDecoder().decode(T.self, from: data)
//            return decodedObject
//        } catch {
//            return nil
//        }
//    }
    
//    func getRecord(for remoteDataType: RemoteDataType) {
//        // Use load json to load 
//        loadLocalSettingsFromJSON(name: <#T##String#>, of: <#T##(Decodable & Encodable).Type#>)
//    }

//    static func getRecord<T: Codable>(for rule: RemoteSettingsFetchConfig.Rule,
//                                      type: T.Type) -> T? {
//        let fileName = rule.file.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? ""
//        switch fileName {
//        case RemoteDataType.passwordRules.fileName:
//            return loadJSON(fileName: fileName, type: type)
//            // NOTE: Add cases for other files (ex. search config v2)
//        default:
//            return nil
//        }
//    }
//
//    // Load the appropriate local data based on the enum case selected
//    func loadLocalSetting<T: Codable>(for settingType: RemoteDataType, as type: T.Type) -> T? {
//        guard let rule = rules.first(where: { $0.name == settingType.name }) else {
//            return nil
//        }
//        
//        return RemoteDataType.loadRecord(for: rule, type: type)
//    }
}
