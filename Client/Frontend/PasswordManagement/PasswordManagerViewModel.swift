// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared
import AuthenticationServices

struct NewSearchInProgressError: MaybeErrorType {
    public let description: String
}

// MARK: - Main View Model
// Login List View Model
final class PasswordManagerViewModel {
    private(set) var profile: Profile
    private(set) var isDuringSearchControllerDismiss = false
    private(set) var count = 0
    private(set) var hasData = false
    weak var searchController: UISearchController?
    weak var delegate: LoginViewModelDelegate?
    private(set) var titles = [Character]()
    private(set) var loginRecordSections = [Character: [LoginRecord]]() {
        didSet {
            ensureMainThread {
                self.delegate?.loginSectionsDidUpdate()
            }
        }
    }
    let listSelectionHelper = PasswordManagerSelectionHelper()
    fileprivate let helper = PasswordManagerDataSourceHelper()
    private(set) lazy var breachAlertsManager: BreachAlertsManager = {
        return BreachAlertsManager(profile: self.profile)
    }()
    private(set) var userBreaches: Set<LoginRecord>?
    private(set) var breachIndexPath = Set<IndexPath>() {
        didSet {
            delegate?.breachPathDidUpdate()
        }
    }
    var hasLoadedBreaches = false
    var theme: Theme

    init(profile: Profile, searchController: UISearchController, theme: Theme) {
        self.profile = profile
        self.searchController = searchController
        self.theme = theme
    }

    func loadLogins(_ query: String? = nil, loginDataSource: LoginDataSource) {
        // Fill in an in-flight query and re-query
        queryLogins(query ?? "") { [weak self] logins in
            self?.setLogins(logins)
            // Loading breaches is a heavy operation hence loading it once per opening logins screen
            guard self?.hasLoadedBreaches == false else { return }
            self?.breachAlertsManager.loadBreaches(completion: { _ in
                guard let self = self else { return }

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
            })
        }
    }

    /// Searches SQLite database for logins that match query.
    /// Wraps the SQLiteLogins method to allow us to cancel it from our end.
    func queryLogins(_ query: String, completion: @escaping (([LoginRecord]) -> Void)) {
        profile.logins.searchLoginsWithQuery(query).upon { result in
            ensureMainThread {
                // Check any failure, Ex. database is closed
                guard result.failureValue == nil else {
                    self.delegate?.loginSectionsDidUpdate()
                    completion([])
                    return
                }
                // Make sure logins exist
                guard let logins = result.successValue else {
                    completion([])
                    return
                }
                completion(logins.asArray())
            }
        }
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

        return section[safe: indexPath.row]
    }

    func indexPathForLogin(_ login: LoginRecord) -> IndexPath? {
        let title = self.helper.titleForLogin(login)
        guard let section = self.titles.firstIndex(of: title),
              let row = self.loginRecordSections[title]?.firstIndex(of: login)
        else { return nil }

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
        helper.computeSectionsFromLogins(logins) { [weak self] result in
            let titles = result.0
            let sections = result.1
            guard !logins.isEmpty else {
                self?.count = 0
                self?.hasData = false
                self?.titles = []
                self?.loginRecordSections = [:]
                return
            }

            self?.count = logins.count
            self?.hasData = !logins.isEmpty
            self?.titles = titles
            self?.loginRecordSections = sections

            // Disable the search controller if there are no logins saved
            if !(self?.searchController?.isActive ?? true) {
                self?.searchController?.searchBar.isUserInteractionEnabled = !logins.isEmpty
                self?.searchController?.searchBar.alpha = logins.isEmpty ? 0.5 : 1.0
            }
        }
    }

    public func save(loginRecord: LoginEntry, completion: @escaping ((String?) -> Void)) {
        profile.logins.addLogin(login: loginRecord).upon { result in
            completion(result.successValue)
        }
    }

    func setBreachIndexPath(indexPath: IndexPath) {
        self.breachIndexPath = [indexPath]
    }

    func setBreachAlertsManager(_ client: BreachAlertsClientProtocol) {
        self.breachAlertsManager = BreachAlertsManager(client, profile: profile)
    }

    // MARK: - UX Constants
    struct UX {
        static let rowHeight: CGFloat = 58
        static let searchHeight: CGFloat = 58
        static let selectionButtonFont = UIFont.systemFont(ofSize: 16)
        static let noResultsFont = UIFont.systemFont(ofSize: 16)
    }
}

// MARK: - LoginDataSourceViewModelDelegate
protocol LoginViewModelDelegate: AnyObject {
    func loginSectionsDidUpdate()
    func breachPathDidUpdate()
}
