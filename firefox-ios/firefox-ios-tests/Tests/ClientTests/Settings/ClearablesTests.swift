// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import CommonMocks
import Shared
import Testing
import WebKit
@testable import Client

@Suite("CookiesClearable")
struct CookiesClearableTests {
    @Test
    func test_cookieDataTypes_containsExpectedTypes() {
        let types = CookiesClearable.cookieDataTypes
        #expect(types.contains(WKWebsiteDataTypeCookies))
        #expect(types.contains(WKWebsiteDataTypeLocalStorage))
        #expect(types.contains(WKWebsiteDataTypeSessionStorage))
        #expect(types.contains(WKWebsiteDataTypeWebSQLDatabases))
        #expect(types.contains(WKWebsiteDataTypeIndexedDBDatabases))
    }

    @MainActor
    @Test
    func test_clear_returnsSuccess() async {
        let result: Maybe<Void> = await withCheckedContinuation { continuation in
            makeSubject().clear().upon { continuation.resume(returning: $0) }
        }
        #expect(result.isSuccess)
    }

    @MainActor
    @Test
    func test_clearForDomain_withEmptyStore_storeRemainsEmpty() async {
        let store = WKWebsiteDataStore.nonPersistent()
        await makeSubject(dataStore: store).clear(forDomain: "example.com")
        let records = await store.dataRecords(ofTypes: CookiesClearable.cookieDataTypes)
        #expect(records.isEmpty)
    }

    @MainActor
    @Test
    func test_clearForDomain_withMatchingDomain_removesOnlyMatchingCookies() async {
        let store = WKWebsiteDataStore.nonPersistent()
        await store.httpCookieStore.setCookie(makeCookie(domain: "example.com"))
        await store.httpCookieStore.setCookie(makeCookie(domain: "other.com"))

        #expect(await store.httpCookieStore.allCookies().count == 2)

        await makeSubject(dataStore: store).clear(forDomain: "example.com")

        let after = await store.httpCookieStore.allCookies()
        #expect(after.count == 1)
        #expect(after.first?.domain == "other.com")
    }

    @MainActor
    @Test
    func test_clearForDomain_withBaseDomain_removesSubdomainCookies() async {
        let store = WKWebsiteDataStore.nonPersistent()
        await store.httpCookieStore.setCookie(makeCookie(domain: "mail.example.com"))
        await store.httpCookieStore.setCookie(makeCookie(domain: "docs.example.com"))
        await store.httpCookieStore.setCookie(makeCookie(domain: "other.com"))

        await makeSubject(dataStore: store).clear(forDomain: "example.com")

        let after = await store.httpCookieStore.allCookies()
        #expect(after.count == 1)
        #expect(after.first?.domain == "other.com")
    }

    @MainActor
    private func makeSubject(dataStore: WKWebsiteDataStore = .nonPersistent()) -> CookiesClearable {
        CookiesClearable(logger: MockLogger(), dataStore: dataStore)
    }

    private func makeCookie(domain: String) -> HTTPCookie {
        HTTPCookie(properties: [
            .name: "test",
            .value: "1",
            .domain: domain,
            .path: "/"
        ])!
    }
}
