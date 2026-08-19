/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import MozillaAppServices
import XCTest

final class OhttpManagerTests: XCTestCase {
    private let configUrl = URL(string: "https://example.com/ohttp-configs")!
    private let otherConfigUrl = URL(string: "https://other.example.com/ohttp-configs")!
    private let relayUrl = URL(string: "https://relay.example.com/")!

    /// The key cache is exercised directly, so the network is never reached.
    private func createSubject() -> OhttpManager {
        return OhttpManager(configUrl: configUrl,
                            relayUrl: relayUrl,
                            network: { _ in (Data(), URLResponse()) })
    }

    func testCachedKeyReturnsNilWhenNothingStored() async {
        let subject = createSubject()

        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertNil(key)
    }

    func testCachedKeyReturnsStoredKeyWithinTTL() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)

        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertEqual(key, [1, 2, 3])
    }

    func testCachedKeyIsScopedPerConfigUrl() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)

        let key = await subject.cachedKey(for: otherConfigUrl, ttl: 3600)

        XCTAssertNil(key)
    }

    func testCachedKeyReturnsNilWhenEntryIsStale() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)

        let key = await subject.cachedKey(for: configUrl, ttl: -1)

        XCTAssertNil(key)
    }

    func testStaleEntryIsEvictedAndNotReturnedLater() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)

        // Reading with an expired TTL should drop the entry, not just report it stale.
        _ = await subject.cachedKey(for: configUrl, ttl: -1)
        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertNil(key)
    }

    func testStoreOverwritesPreviousKey() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)
        await subject.store(key: [4, 5, 6], for: configUrl)

        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertEqual(key, [4, 5, 6])
    }

    func testInvalidateKeyRemovesStoredKey() async {
        let subject = createSubject()
        await subject.store(key: [1, 2, 3], for: configUrl)

        await subject.invalidateKey(for: configUrl)
        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertNil(key)
    }

    /// Regression cover for the unsynchronised static cache this actor replaced:
    /// interleaved reads, writes and evictions corrupted it, and the crash
    /// surfaced while releasing torn values.
    func testConcurrentAccessKeepsCacheConsistent() async {
        let subject = createSubject()
        let urls = [configUrl, otherConfigUrl]

        await withTaskGroup(of: Void.self) { group in
            for iteration in 0..<500 {
                let url = urls[iteration % urls.count]

                group.addTask {
                    await subject.store(key: [UInt8(iteration % 256)], for: url)
                }
                group.addTask {
                    _ = await subject.cachedKey(for: url, ttl: 3600)
                }
                group.addTask {
                    _ = await subject.cachedKey(for: url, ttl: -1)
                }
                group.addTask {
                    await subject.invalidateKey(for: url)
                }
            }
        }

        // The cache must still be usable after the hammering.
        await subject.store(key: [9], for: configUrl)
        let key = await subject.cachedKey(for: configUrl, ttl: 3600)

        XCTAssertEqual(key, [9])
    }
}
