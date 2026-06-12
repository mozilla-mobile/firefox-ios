// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import WebKit

@MainActor
enum CertificateExceptionClearing {
    static func clearSelectedWebsiteData(_ records: [WKWebsiteDataRecord]) async {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        await WKWebsiteDataStore.default().removeData(ofTypes: types, for: records)
        clearExceptions(forDomains: Set(records.map(\.displayName)))
    }

    static func clearAllWebsiteData() async {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        await WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast)
        clearExceptions(forDomains: nil)
    }

    static func clearStoredExceptionsIfWebsiteDataCleared(
        clearables: [(clearable: Clearable, checked: Bool)],
        toggles: [Bool],
        profile: Profile
    ) {
        let clearsWebsiteData = clearables.enumerated().contains { i, pair in
            toggles[i] && (pair.clearable is CookiesClearable || pair.clearable is SiteDataClearable)
        }
        guard clearsWebsiteData else { return }
        clearExceptions(forDomains: nil, profile: profile)
    }

    private static func clearExceptions(forDomains domains: Set<String>?, profile: Profile? = nil) {
        let profile = profile ?? AppContainer.shared.resolve() as Profile
        if let domains {
            profile.certStore.removeCertificates(forDomains: domains)
        } else {
            profile.certStore.removeAll()
        }
        clearURLCredentialStorage(forDomains: domains)
    }

    private static func clearURLCredentialStorage(forDomains domains: Set<String>?) {
        let storage = URLCredentialStorage.shared
        for (space, credentials) in storage.allCredentials {
            guard space.authenticationMethod == NSURLAuthenticationMethodServerTrust else { continue }
            guard let domains else {
                credentials.values.forEach { storage.remove($0, for: space) }
                continue
            }
            let host = space.host.lowercased()
            if domains.contains(where: { host == $0.lowercased() || host.hasSuffix(".\($0.lowercased())") }) {
                credentials.values.forEach { storage.remove($0, for: space) }
            }
        }
    }
}
