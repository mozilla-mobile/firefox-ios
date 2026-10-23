// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Security
import XCTest

@testable import Storage

final class RustKeychainCleanupTests: XCTestCase {
    func testWipePreservesHistoryAndDeletesOtherItems() throws {
        let keychain = MockCleanupKeychainClient()
        let history = KeychainProtectedItem.installationHistory
        keychain.items = [
            item(service: history.service, account: history.account, reference: "history"),
            item(service: history.service, account: "other", reference: "other-account"),
            item(service: "unknown", account: history.account, reference: "unknown-service")
        ]

        RustKeychain.wipeKeychain(keychain: keychain)

        let referenceDeletes = keychain.deletedQueries.filter { $0[kSecValuePersistentRef as String] != nil }
        let deleted = try referenceDeletes.map { query in
            XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
            XCTAssertEqual(query.count, 2)
            return try XCTUnwrap(query[kSecValuePersistentRef as String] as? Data)
        }
        XCTAssertEqual(Set(deleted), Set(["other-account", "unknown-service"].map { Data($0.utf8) }))
        let bulkDeletes = keychain.deletedQueries.filter { $0[kSecValuePersistentRef as String] == nil }
        let expectedClasses = [kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        XCTAssertEqual(Set(bulkDeletes.compactMap { $0[kSecClass as String] as? String }),
                       Set(expectedClasses.map { $0 as String }))
    }

    func testFailedEnumerationDoesNotDeleteItems() {
        for status in [errSecItemNotFound, errSecInteractionNotAllowed] {
            let keychain = MockCleanupKeychainClient()
            keychain.loadStatus = status

            let result = deleteKeychainSecClass(kSecClassGenericPassword, keychain: keychain)

            XCTAssertEqual(result, status)
            XCTAssertEqual(keychain.loadedQueries.count, 1)
            XCTAssertTrue(keychain.deletedQueries.isEmpty)

            let subject = RustKeychain(serviceName: KeychainProtectedItem.installationHistory.service,
                                       keychain: keychain)
            subject.removeAllKeys()

            XCTAssertEqual(keychain.loadedQueries.count, 2)
            XCTAssertTrue(keychain.deletedQueries.isEmpty)
        }
    }

    func testMalformedEnumerationResultDoesNotDeleteItems() {
        let keychain = MockCleanupKeychainClient()
        keychain.loadResult = Data("invalid result".utf8) as NSData

        let status = deleteKeychainSecClass(kSecClassGenericPassword, keychain: keychain)

        XCTAssertEqual(status, errSecDecode)
        XCTAssertEqual(keychain.loadedQueries.count, 1)
        XCTAssertTrue(keychain.deletedQueries.isEmpty)
    }

    func testMissingPersistentReferenceDoesNotPreventDeletingOtherItems() throws {
        let keychain = MockCleanupKeychainClient()
        var missingReference = item(service: "unknown", account: "first", reference: "first")
        missingReference.removeValue(forKey: kSecValuePersistentRef as String)
        keychain.items = [
            missingReference,
            item(service: "unknown", account: "second", reference: "second")
        ]

        let status = deleteKeychainSecClass(kSecClassGenericPassword, keychain: keychain)

        XCTAssertEqual(status, errSecDecode)
        XCTAssertEqual(keychain.deletedQueries.count, 1)
        let expected: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecValuePersistentRef as String: Data("second".utf8)
        ]
        XCTAssertEqual(try XCTUnwrap(keychain.deletedQueries.first) as NSDictionary, expected as NSDictionary)
    }

    func testFailedDeletionDoesNotPreventAttemptingOtherUnprotectedItems() {
        let keychain = MockCleanupKeychainClient()
        keychain.items = [
            item(service: "unknown", account: "first", reference: "first"),
            item(service: "unknown", account: "second", reference: "second")
        ]
        keychain.deleteStatus = errSecInteractionNotAllowed

        let status = deleteKeychainSecClass(kSecClassGenericPassword, keychain: keychain)

        XCTAssertEqual(status, errSecInteractionNotAllowed)
        XCTAssertEqual(keychain.deletedQueries.count, 2)
    }

    func testRemoveAllKeysPreservesHistoryInItsServiceAndAccessGroup() throws {
        let keychain = MockCleanupKeychainClient()
        let history = KeychainProtectedItem.installationHistory
        keychain.items = [
            item(service: history.service, account: history.account, reference: "history"),
            item(service: history.service, account: "unknown", reference: "credential")
        ]
        let subject = RustKeychain(serviceName: history.service, accessGroup: "APPID.shared", keychain: keychain)

        subject.removeAllKeys()

        let query = try XCTUnwrap(keychain.loadedQueries.first)
        XCTAssertEqual(query[kSecAttrService as String] as? String, history.service)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "APPID.shared")
        XCTAssertEqual(keychain.deletedQueries.count, 1)
        XCTAssertEqual(keychain.deletedQueries.first?[kSecValuePersistentRef as String] as? Data,
                       Data("credential".utf8))
    }

    func testRemoveAllKeysKeepsBulkDeletionForAnUnprotectedService() throws {
        for accessGroup in [nil, "APPID.shared"] {
            let keychain = MockCleanupKeychainClient()
            let subject = RustKeychain(serviceName: "unprotected-service", accessGroup: accessGroup, keychain: keychain)

            subject.removeAllKeys()

            XCTAssertTrue(keychain.loadedQueries.isEmpty)
            XCTAssertEqual(keychain.deletedQueries.count, 1)
            var expected: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "unprotected-service"
            ]
            expected[kSecAttrAccessGroup as String] = accessGroup
            XCTAssertEqual(try XCTUnwrap(keychain.deletedQueries.first) as NSDictionary, expected as NSDictionary)
        }
    }

    private func item(service: String, account: String, reference: String) -> [String: Any] {
        [kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecAttrAccessGroup as String: "APPID.shared",
         kSecAttrSynchronizable as String: false,
         kSecValuePersistentRef as String: Data(reference.utf8)]
    }
}

private final class MockCleanupKeychainClient: KeychainClient, @unchecked Sendable {
    var items: [[String: Any]]?
    var loadStatus: OSStatus?
    var loadResult: CFTypeRef?
    var deleteStatus = errSecSuccess
    private(set) var loadedQueries: [[String: Any]] = []
    private(set) var deletedQueries: [[String: Any]] = []

    func load(query: [String: Any]) -> (OSStatus, CFTypeRef?) {
        loadedQueries.append(query)
        if let loadStatus {
            return (loadStatus, nil)
        }
        if let loadResult {
            return (errSecSuccess, loadResult)
        }
        guard let items else {
            return (errSecItemNotFound, nil)
        }
        return (errSecSuccess, items as NSArray)
    }

    func delete(query: [String: Any]) -> OSStatus {
        deletedQueries.append(query)
        return deleteStatus
    }

    func update(query: [String: Any], attributes: [String: Any]) -> OSStatus {
        XCTFail("Cleanup must not update items")
        return errSecUnimplemented
    }

    func add(attributes: [String: Any]) -> OSStatus {
        XCTFail("Cleanup must not add items")
        return errSecUnimplemented
    }
}
