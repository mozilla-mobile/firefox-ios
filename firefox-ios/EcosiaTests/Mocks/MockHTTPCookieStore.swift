// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import WebKit

class MockHTTPCookieStore: CookieStoreProtocol {
    private var cookies: [HTTPCookie] = []

    func allCookies() async -> [HTTPCookie] {
        return cookies
    }

    func setCookie(_ cookie: HTTPCookie) async {
        // Remove existing cookie with same name/domain/path
        cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
        cookies.append(cookie)
    }
}
