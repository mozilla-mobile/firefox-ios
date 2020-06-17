/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

// MARK: - Main View Model
// Login List View Model
final class LoginListViewModel {

    let profile: Profile
    fileprivate var activeLoginQuery: Deferred<Maybe<[LoginRecord]>>? = nil
    var dataSource: ModelTypeLoginDataSource
    var isDuringSearchControllerDismiss = false

    init(profile: Profile, searchController: UISearchController) {
        self.profile = profile
        self.dataSource = ModelTypeLoginDataSource(searchController)
    }

    func loadLogins(_ query: String? = nil, loginDataSource: LoginDataSource) {
        // Fill in an in-flight query and re-query
        activeLoginQuery?.fillIfUnfilled(Maybe(success: []))
        activeLoginQuery = queryLogins(query ?? "")
        activeLoginQuery! >>== dataSource.setLogins
    }
    
    /// Searches SQLite database for logins that match query.
    /// Wraps the SQLiteLogins method to allow us to cancel it from our end.
    func queryLogins(_ query: String) -> Deferred<Maybe<[LoginRecord]>> {
        let deferred = Deferred<Maybe<[LoginRecord]>>()
        profile.logins.searchLoginsWithQuery(query) >>== { logins in
            deferred.fillIfUnfilled(Maybe(success: logins.asArray()))
            succeed()
        }
        return deferred
    }

    // MARK: - UX Constants
    struct LoginListUX {
        static let RowHeight: CGFloat = 58
        static let SearchHeight: CGFloat = 58
        static let selectionButtonFont = UIFont.systemFont(ofSize: 16)
        static let NoResultsFont = UIFont.systemFont(ofSize: 16)
        static let NoResultsTextColor = UIColor.Photon.Grey40
    }

    class ModelTypeLoginDataSource {
        var count = 0
        weak var searchController: UISearchController?
        var titles = [Character]()
        var loginRecordSections = [Character: [LoginRecord]]() {
            didSet {
                assert(Thread.isMainThread)
                delegate?.loginSectionsDidUpdate() // based on Kayla's sample project
            }
        }
        fileprivate let helper = LoginListDataSourceHelper()
        weak var delegate: LoginDataSourceDelegate?

        init(_ searchController: UISearchController) {
            self.searchController = searchController
        }

        func loginAtIndexPath(_ indexPath: IndexPath) -> LoginRecord? {
            guard indexPath.section > 0 else {
                assertionFailure()
                return nil
            }
            let titleForSectionIndex = titles[indexPath.section - 1]
            guard let section = loginRecordSections[titleForSectionIndex] else {
                assertionFailure()
                return nil
            }

            assert(indexPath.row <= section.count)

            return section[indexPath.row]
        }

        func loginsForSection(_ section: Int) -> [LoginRecord]? {
            guard section > 0 else {
                assertionFailure()
                return nil
            }
            let titleForSectionIndex = titles[section - 1]
            return loginRecordSections[titleForSectionIndex]
        }

        func setLogins(_ logins: [LoginRecord]) {
            // NB: Make sure we call the callback on the main thread so it can be synced up with a reloadData to
            //     prevent race conditions between data/UI indexing.
            return self.helper.computeSectionsFromLogins(logins).uponQueue(.main) { result in
                guard let (titles, sections) = result.successValue else {
                    self.count = 0
                    self.titles = []
                    self.loginRecordSections = [:]
                    return
                }

                self.count = logins.count
                self.titles = titles
                self.loginRecordSections = sections

                // Disable the search controller if there are no logins saved
                if !(self.searchController?.isActive ?? true) {
                    self.searchController?.searchBar.isUserInteractionEnabled = !logins.isEmpty
                    self.searchController?.searchBar.alpha = logins.isEmpty ? 0.5 : 1.0
                }
            }
        }
    }
}
// MARK: - LoginDataSourceViewModelDelegate
protocol LoginDataSourceDelegate: AnyObject {
    func loginSectionsDidUpdate()
}

// MARK: - Data Source
private class LoginListDataSourceHelper {
    var domainLookup = [GUID: (baseDomain: String?, host: String?, hostname: String)]()

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

    func computeSectionsFromLogins(_ logins: [LoginRecord]) -> Deferred<Maybe<([Character], [Character: [LoginRecord]])>> {
        guard logins.count > 0 else {
            return deferMaybe( ([Character](), [Character: [LoginRecord]]()) )
        }

        var sections = [Character: [LoginRecord]]()
        var titleSet = Set<Character>()

        return deferDispatchAsync(DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass)) {
            // Precompute the baseDomain, host, and hostname values for sorting later on. At the moment
            // baseDomain() is a costly call because of the ETLD lookup tables.
            logins.forEach { login in
                self.domainLookup[login.id] = (
                    login.hostname.asURL?.baseDomain,
                    login.hostname.asURL?.host,
                    login.hostname
                )
            }

            // 1. Temporarily insert titles into a Set to get duplicate removal for 'free'.
            logins.forEach { titleSet.insert(self.titleForLogin($0)) }

            // 2. Setup an empty list for each title found.
            titleSet.forEach { sections[$0] = [LoginRecord]() }

            // 3. Go through our logins and put them in the right section.
            logins.forEach { sections[self.titleForLogin($0)]?.append($0) }

            // 4. Go through each section and sort.
            sections.forEach { sections[$0] = $1.sorted(by: self.sortByDomain) }

            return deferMaybe( (Array(titleSet).sorted(), sections) )
        }
    }
}
