/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

// MARK: - Main View Model
// Login List View Model
final class LoginListViewModel {

    private(set) var profile: Profile
    private(set) var isDuringSearchControllerDismiss = false
    private(set) var count = 0
    weak var searchController: UISearchController?
    weak var delegate: LoginViewModelDelegate?
    private(set) var activeLoginQuery: Deferred<Maybe<[LoginRecord]>>?
    private(set) var titles = [Character]()
    private(set) var loginRecordSections = [Character: [LoginRecord]]() {
        didSet {
            assert(Thread.isMainThread)
            delegate?.loginSectionsDidUpdate()
        }
    }
    fileprivate let helper = LoginListDataSourceHelper()
    private(set) lazy var breachAlertsManager: BreachAlertsManager = {
        return BreachAlertsManager(profile: self.profile)
    }()
    private(set) var userBreaches: Set<LoginRecord>?
    private(set) var breachIndexPath = Set<IndexPath>() {
        didSet {
            delegate?.breachPathDidUpdate()
        }
    }
    var hasLoadedBreaches: Bool = false
    init(profile: Profile, searchController: UISearchController) {
        self.profile = profile
        self.searchController = searchController
    }

    func loadLogins(_ query: String? = nil, loginDataSource: LoginDataSource) {
        // Fill in an in-flight query and re-query
        activeLoginQuery?.fillIfUnfilled(Maybe(success: []))
        activeLoginQuery = queryLogins(query ?? "")
        activeLoginQuery! >>== self.setLogins
        // Loading breaches is a heavy operation hence loading it once per opening logins screen
        guard !hasLoadedBreaches else { return }
        breachAlertsManager.loadBreaches { [weak self] _ in
            guard let self = self, let logins = self.activeLoginQuery?.value.successValue else { return }
            self.userBreaches = self.breachAlertsManager.findUserBreaches(logins).successValue
            guard let breaches = self.userBreaches else { return }
            var indexPaths = Set<IndexPath>()
            for breach in breaches {
                if logins.contains(breach), let indexPath = self.indexPathForLogin(breach) {
                    indexPaths.insert(indexPath)
                }
            }
            self.breachIndexPath = indexPaths
            self.hasLoadedBreaches = true
        }
    }

    /// Searches SQLite database for logins that match query.
    /// Wraps the SQLiteLogins method to allow us to cancel it from our end.
    func queryLogins(_ query: String) -> Deferred<Maybe<[LoginRecord]>> {
        let deferred = Deferred<Maybe<[LoginRecord]>>()
        profile.logins.searchLoginsWithQuery(query).upon { result in
            // Check any failure, Ex. database is closed
            guard result.failureValue == nil else {
                DispatchQueue.main.async {
                    self.delegate?.loginSectionsDidUpdate()
                }
                return
            }
            // Make sure logins exist
            guard let logins = result.successValue else { return }
            deferred.fillIfUnfilled(Maybe(success: logins.asArray()))
            succeed()
        }
        return deferred
    }

    func setIsDuringSearchControllerDismiss(to: Bool) {
        self.isDuringSearchControllerDismiss = to
    }

    // MARK: - Data Source Methods
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

    func indexPathForLogin(_ login: LoginRecord) -> IndexPath? {
        let title = self.helper.titleForLogin(login)
        guard let section = self.titles.firstIndex(of: title), let row = self.loginRecordSections[title]?.firstIndex(of: login) else {
            return nil
        }
        return IndexPath(row: row, section: section+1)
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
            guard let (titles, sections) = result.successValue, logins.count > 0 else {
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

    func setBreachIndexPath(indexPath: IndexPath) {
        self.breachIndexPath = [indexPath]
    }

    func setBreachAlertsManager(_ client: BreachAlertsClientProtocol) {
        self.breachAlertsManager = BreachAlertsManager(client, profile: profile)
    }

    // MARK: - UX Constants
    struct LoginListUX {
        static let RowHeight: CGFloat = 58
        static let SearchHeight: CGFloat = 58
        static let selectionButtonFont = UIFont.systemFont(ofSize: 16)
        static let NoResultsFont = UIFont.systemFont(ofSize: 16)
        static let NoResultsTextColor = UIColor.Photon.Grey40
    }
}

// MARK: - LoginDataSourceViewModelDelegate
protocol LoginViewModelDelegate: AnyObject {
    func loginSectionsDidUpdate()
    func breachPathDidUpdate()
}

extension LoginRecord: Equatable, Hashable {
    public static func == (lhs: LoginRecord, rhs: LoginRecord) -> Bool {
        return lhs.id == rhs.id && lhs.hostname == rhs.hostname && lhs.credentials == rhs.credentials
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
