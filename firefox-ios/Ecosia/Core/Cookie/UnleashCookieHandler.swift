// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class UnleashCookieHandler: BaseCookieHandler {

    private let unleash: UnleashProtocol.Type

    init(unleash: UnleashProtocol.Type = Unleash.self) {
        self.unleash = unleash
        super.init(cookieName: Cookie.unleash.rawValue)
    }

    override func getCookieValue() -> String? {
        guard unleash.isLoaded else {
            return nil
        }
        return Unleash.userId.uuidString.lowercased()
    }

    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        if let nativeIdCooke = makeCookie() {
            // Force override Unleash cookie with native Id when it changes
            if cookie.value != nativeIdCooke.value {
                Task {
                    await cookieStore.setCookie(nativeIdCooke)
                }
            }
        }
    }
}
