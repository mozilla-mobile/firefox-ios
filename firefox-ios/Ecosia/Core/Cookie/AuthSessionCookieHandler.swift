// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class AuthSessionCookieHandler: BaseCookieHandler {

    init() {
        super.init(cookieName: Cookie.authSession.rawValue)
    }
}
