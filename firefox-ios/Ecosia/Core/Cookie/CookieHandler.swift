// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

// MARK: - Cookie Handler Protocol

protocol CookieHandler {
    var cookieName: String { get }
    func makeCookie() -> HTTPCookie?
    func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol)
}

// MARK: - Base Cookie Handler

class BaseCookieHandler: CookieHandler {
    let cookieName: String

    init(cookieName: String) {
        self.cookieName = cookieName
    }

    func makeCookie() -> HTTPCookie? {
        guard let value = getCookieValue() else { return nil }
        return createHTTPCookie(value: value)
    }

    func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        // Override in subclasses
    }

    // MARK: - Helper methods

    func createHTTPCookie(value: String) -> HTTPCookie? {
        let urlProvider = Cookie.urlProvider
        return HTTPCookie(properties: [
            .name: cookieName,
            .domain: ".\(urlProvider.domain)",
            .path: "/",
            .value: value
        ])
    }

    func getCookieValue() -> String? {
        // Override in subclasses
        return nil
    }
}
