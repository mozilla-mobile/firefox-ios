// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLRequest {

    public mutating func withCloudFlareAuthParameters(environment: Environment = EcosiaEnvironment.current) -> URLRequest {
        if let auth = environment.cloudFlareAuth {
            setValue(auth.id, forHTTPHeaderField: CloudflareKeyProvider.clientId)
            setValue(auth.secret, forHTTPHeaderField: CloudflareKeyProvider.clientSecret)
        }
        return self
    }

    /// This function provides an additional HTTP request header when loading SERP through native UI (i.e. submitting a search)
    /// to help SERP decide which market to serve.
    public mutating func addLanguageRegionHeader() {
        setValue(Locale.current.identifierWithDashedLanguageAndRegion, forHTTPHeaderField: "x-ecosia-app-language-region")
    }
}
