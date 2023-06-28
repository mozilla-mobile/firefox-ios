// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import Shared

class PasswordManagerDataSourceHelper {
    private(set) var domainLookup = [GUID: (baseDomain: String?, host: String?, hostname: String)]()

    // Precompute the baseDomain, host, and hostname values for sorting later on. At the moment
    // baseDomain() is a costly call because of the ETLD lookup tables.
    func setDomainLookup(_ logins: [LoginRecord]) {
        self.domainLookup = [:]
        logins.forEach { login in
            self.domainLookup[login.id] = (
                login.hostname.asURL?.baseDomain,
                login.hostname.asURL?.host,
                login.hostname
            )
        }
    }

    // Small helper method for using the precomputed base domain to determine the title/section of the
    // given login.
    func titleForLogin(_ login: LoginRecord) -> Character {
        // Fallback to hostname if we can't extract a base domain.
        let titleString = domainLookup[login.id]?.baseDomain?.uppercased() ?? login.hostname
        return titleString.first ?? Character("")
    }

    // Rules for sorting login URLS:
    // 1. Compare base domains
    // 2. If bases are equal, compare hosts
    // 3. If login URL was invalid, revert to full hostname
    func sortByDomain(_ loginA: LoginRecord, loginB: LoginRecord) -> Bool {
        guard let domainsA = domainLookup[loginA.id],
              let domainsB = domainLookup[loginB.id] else {
            return false
        }

        guard let baseDomainA = domainsA.baseDomain,
              let baseDomainB = domainsB.baseDomain,
              let hostA = domainsA.host,
            let hostB = domainsB.host else {
            return domainsA.hostname < domainsB.hostname
        }

        if baseDomainA == baseDomainB {
            return hostA < hostB
        } else {
            return baseDomainA < baseDomainB
        }
    }

    func computeSectionsFromLogins(_ logins: [LoginRecord], completion: @escaping ((([Character], [Character: [LoginRecord]])) -> Void)) {
        guard !logins.isEmpty else {
            completion( ([Character](), [Character: [LoginRecord]]()) )
            return
        }

        var sections = [Character: [LoginRecord]]()
        var titleSet = Set<Character>()

        self.setDomainLookup(logins)
        // 1. Temporarily insert titles into a Set to get duplicate removal for 'free'.
        logins.forEach { titleSet.insert(self.titleForLogin($0)) }

        // 2. Setup an empty list for each title found.
        titleSet.forEach { sections[$0] = [LoginRecord]() }

        // 3. Go through our logins and put them in the right section.
        logins.forEach { sections[self.titleForLogin($0)]?.append($0) }

        // 4. Go through each section and sort.
        sections.forEach { sections[$0] = $1.sorted(by: self.sortByDomain) }

        completion( (Array(titleSet).sorted(), sections) )
    }
}
