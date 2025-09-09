// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

final class ConsentCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.consent.rawValue)
    }

    override func getCookieValue() -> String? {
        return User.shared.cookieConsentValue
    }

    override func received(_ cookie: HTTPCookie, in cookieStore: CookieStoreProtocol) {
        User.shared.cookieConsentValue = cookie.value
    }
}
