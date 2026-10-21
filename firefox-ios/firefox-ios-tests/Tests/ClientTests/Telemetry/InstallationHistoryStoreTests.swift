// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Security
import Storage
import XCTest

@testable import Client

@MainActor
final class InstallationHistoryStoreTests: XCTestCase {
    private var keychain: MockInstallationKeychain!
    private var subject: InstallationHistoryStore!

    override func setUp() async throws {
        try await super.setUp()
        keychain = MockInstallationKeychain()
        subject = InstallationHistoryStore(keychain: keychain)
    }

    override func tearDown() async throws {
        subject = nil
        keychain = nil
        try await super.tearDown()
    }

    func testLoadMissingHistory() throws {
        XCTAssertEqual(try subject.load(), .missing)
    }

    func testLoadSavedHistory() throws {
        let history = InstallationHistory(installCounter: 2, lastSeenDate: Date(timeIntervalSince1970: 0))
        keychain.loadStatus = errSecSuccess
        keychain.loadResult = try JSONEncoder().encode(history) as NSData

        XCTAssertEqual(try subject.load(), .valid(history))
        let query = try XCTUnwrap(keychain.loadedQueries.first)
        XCTAssertEqual(query[kSecAttrService as String] as? String, "org.mozilla.firefox.installation-history")
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "installation-history")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, false)
    }

    func testLoadCorruptHistory() throws {
        keychain.loadStatus = errSecSuccess
        keychain.loadResult = Data("broken".utf8) as NSData
        XCTAssertEqual(try subject.load(), .corrupt)

        keychain.loadResult = try JSONEncoder().encode(
            InstallationHistory(installCounter: 0, lastSeenDate: Date(timeIntervalSince1970: 0))
        ) as NSData
        XCTAssertEqual(try subject.load(), .corrupt)
    }

    func testSaveNewHistory() throws {
        keychain.updateStatus = errSecItemNotFound
        let history = InstallationHistory(installCounter: 1, lastSeenDate: Date(timeIntervalSince1970: 0))

        try subject.save(history)

        XCTAssertEqual(keychain.addedItems.count, 1)
        let item = try XCTUnwrap(keychain.addedItems.first)
        let data = try XCTUnwrap(item[kSecValueData as String] as? Data)
        XCTAssertEqual(try JSONDecoder().decode(InstallationHistory.self, from: data), history)
        XCTAssertEqual(item[kSecAttrService as String] as? String, "org.mozilla.firefox.installation-history")
        XCTAssertEqual(item[kSecAttrAccount as String] as? String, "installation-history")
        XCTAssertEqual(item[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        XCTAssertEqual(item[kSecAttrSynchronizable as String] as? Bool, false)
    }

    func testSaveExistingHistory() throws {
        let history = InstallationHistory(installCounter: 2, lastSeenDate: Date(timeIntervalSince1970: 0))

        try subject.save(history)

        XCTAssertEqual(keychain.updatedQueries.count, 1)
        let attributes = try XCTUnwrap(keychain.updatedAttributes)
        let data = try XCTUnwrap(attributes[kSecValueData as String] as? Data)
        XCTAssertEqual(try JSONDecoder().decode(InstallationHistory.self, from: data), history)
        XCTAssertTrue(keychain.addedItems.isEmpty)
    }

    func testKeychainFailuresThrow() {
        keychain.loadStatus = errSecInteractionNotAllowed
        XCTAssertThrowsError(try subject.load())

        let history = InstallationHistory(installCounter: 1, lastSeenDate: Date(timeIntervalSince1970: 0))
        keychain.updateStatus = errSecInteractionNotAllowed
        XCTAssertThrowsError(try subject.save(history))
        XCTAssertTrue(keychain.addedItems.isEmpty)

        keychain.updateStatus = errSecItemNotFound
        keychain.addStatus = errSecMissingEntitlement
        XCTAssertThrowsError(try subject.save(history))
    }

    func testInvalidHistoryIsNotSaved() {
        XCTAssertThrowsError(try subject.save(InstallationHistory(installCounter: 0, lastSeenDate: Date())))
        XCTAssertThrowsError(try subject.save(InstallationHistory(installCounter: 1,
                                                                  lastSeenDate: Date(timeIntervalSince1970: .nan))))
        XCTAssertTrue(keychain.updatedQueries.isEmpty)
        XCTAssertTrue(keychain.addedItems.isEmpty)
    }

    #if DEBUG || MOCKABLE_STORE
    func testResetDeletesOnlyHistoryAndAcceptsMissingItem() throws {
        keychain.deleteStatus = errSecItemNotFound

        try subject.resetForTesting()

        XCTAssertEqual(keychain.deletedQueries.count, 1)
        let query = try XCTUnwrap(keychain.deletedQueries.first)
        let expected: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "org.mozilla.firefox.installation-history",
            kSecAttrAccount as String: "installation-history",
            kSecAttrSynchronizable as String: false
        ]
        XCTAssertEqual(query as NSDictionary, expected as NSDictionary)
    }
    #endif
}

private final class MockInstallationKeychain: KeychainClient, @unchecked Sendable {
    var loadStatus = errSecItemNotFound
    var loadResult: CFTypeRef?
    var updateStatus = errSecSuccess
    var addStatus = errSecSuccess
    var deleteStatus = errSecSuccess
    private(set) var loadedQueries: [[String: Any]] = []
    private(set) var updatedQueries: [[String: Any]] = []
    private(set) var updatedAttributes: [String: Any]?
    private(set) var addedItems: [[String: Any]] = []
    private(set) var deletedQueries: [[String: Any]] = []

    func load(query: [String: Any]) -> (OSStatus, CFTypeRef?) {
        loadedQueries.append(query)
        return (loadStatus, loadResult)
    }

    func update(query: [String: Any], attributes: [String: Any]) -> OSStatus {
        updatedQueries.append(query)
        updatedAttributes = attributes
        return updateStatus
    }

    func add(attributes: [String: Any]) -> OSStatus {
        addedItems.append(attributes)
        return addStatus
    }

    func delete(query: [String: Any]) -> OSStatus {
        deletedQueries.append(query)
        return deleteStatus
    }
}
