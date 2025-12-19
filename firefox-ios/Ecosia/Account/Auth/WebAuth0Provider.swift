// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Auth0

/// Default implementation of `Auth0ProviderProtocol` using Auth0's SDK, utilizing Web Auth Login solely.
public struct WebAuth0Provider: Auth0ProviderProtocol {

    public var webAuth: WebAuth { makeHttpsWebAuth() }

    public init() {}
}
