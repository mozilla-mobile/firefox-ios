// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import Storage

struct InstallationHistory: Codable, Equatable {
    let installCounter: Int64
    let lastSeenDate: Date
}

enum InstallationHistoryState: Equatable {
    case missing
    case valid(InstallationHistory)
    case corrupt
}

@MainActor
protocol InstallationHistoryStoring {
    func load() throws -> InstallationHistoryState
    func save(_ history: InstallationHistory) throws
    #if DEBUG || MOCKABLE_STORE
    func resetForTesting() throws
    #endif
}

enum InstallationHistoryError: Error {
    case keychain(OSStatus)
    case invalidValue
}

struct InstallationHistoryStore: InstallationHistoryStoring {
    private let keychain: any KeychainClient

    init(keychain: any KeychainClient = DefaultKeychainClient()) {
        self.keychain = keychain
    }

    private var itemQuery: [String: Any] {
        let item = KeychainProtectedItem.installationHistory
        return [
            kSecClass as String: item.itemClass,
            kSecAttrService as String: item.service,
            kSecAttrAccount as String: item.account,
            kSecAttrSynchronizable as String: false
        ]
    }

    func load() throws -> InstallationHistoryState {
        var query = itemQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let (status, result) = keychain.load(query: query)

        if status == errSecItemNotFound {
            return .missing
        }
        guard status == errSecSuccess else {
            throw InstallationHistoryError.keychain(status)
        }
        guard let data = result as? Data,
              let history = try? JSONDecoder().decode(
                  InstallationHistory.self,
                  from: data
              ),
              isValid(history) else {
            return .corrupt
        }
        return .valid(history)
    }

    func save(_ history: InstallationHistory) throws {
        guard isValid(history) else {
            throw InstallationHistoryError.invalidValue
        }
        let attributes: [String: Any] = [
            kSecValueData as String: try JSONEncoder().encode(history),
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = keychain.update(query: itemQuery, attributes: attributes)
        if status == errSecSuccess {
            return
        }
        guard status == errSecItemNotFound else {
            throw InstallationHistoryError.keychain(status)
        }

        var newItem = itemQuery
        newItem.merge(attributes) { _, newValue in newValue }
        let addStatus = keychain.add(attributes: newItem)
        guard addStatus == errSecSuccess else {
            throw InstallationHistoryError.keychain(addStatus)
        }
    }

    #if DEBUG || MOCKABLE_STORE
    func resetForTesting() throws {
        let status = keychain.delete(query: itemQuery)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw InstallationHistoryError.keychain(status)
        }
    }
    #endif

    private func isValid(_ history: InstallationHistory) -> Bool {
        history.installCounter > 0 && history.lastSeenDate.timeIntervalSince1970.isFinite
    }
}
