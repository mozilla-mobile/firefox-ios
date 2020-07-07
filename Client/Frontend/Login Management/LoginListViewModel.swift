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
    fileprivate let helper = LoginListViewModelHelper()

    init(profile: Profile, searchController: UISearchController) {
        self.profile = profile
        self.searchController = searchController
    }

    func loadLogins(_ query: String? = nil, loginDataSource: LoginDataSource) {
        // Fill in an in-flight query and re-query
        activeLoginQuery?.fillIfUnfilled(Maybe(success: []))
        activeLoginQuery = queryLogins(query ?? "")
        activeLoginQuery! >>== self.setLogins
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

    func loginsForSection(_ section: Int) -> [LoginRecord]? {
        guard section > 0 else {
            assertionFailure()
            return nil
        }
        let titleForSectionIndex = titles[section - 1]
        return loginRecordSections[titleForSectionIndex]
    }

    private func setLogins(_ logins: [LoginRecord]) {
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
}
