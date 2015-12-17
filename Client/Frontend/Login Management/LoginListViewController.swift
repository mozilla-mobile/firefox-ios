/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage
import Shared

private struct LoginListUX {
    static let RowHeight: CGFloat = 58
    static let SearchHeight: CGFloat = 58
}

class LoginListViewController: UIViewController {

    private var loginDataSource: LoginCursorDataSource? = nil
    private var loginSearchController: LoginSearchController? = nil

    private let profile: Profile

    private let searchView = SearchInputView()

    private lazy var tableView: UITableView = {
        return UITableView()
    }()

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.whiteColor()

        self.title = NSLocalizedString("Logins", comment: "Title for Logins List View screen")
        loginDataSource = LoginCursorDataSource(tableView: self.tableView)
        loginSearchController = LoginSearchController(profile: self.profile, dataSource: loginDataSource!)
        searchView.delegate = loginSearchController

        view.addSubview(searchView)
        view.addSubview(tableView)

        searchView.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom).constraint
            make.left.right.equalTo(self.view)
            make.height.equalTo(LoginListUX.SearchHeight)
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(searchView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        KeyboardHelper.defaultHelper.addDelegate(self)

        profile.logins.getAllLogins().uponQueue(dispatch_get_main_queue()) { result in
            self.loginDataSource?.cursor = result.successValue
            self.tableView.reloadData()
        }
    }
}

extension LoginListViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Force the headers to be hidden
        return 0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return LoginListUX.RowHeight
    }
}

extension LoginListViewController: KeyboardHelperDelegate {
    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

/// Controller that handles interactions with the search widget and updating the data source for searching
private class LoginSearchController: NSObject, SearchInputViewDelegate {

    private let profile: Profile

    private var activeSearchDeferred: Success?

    private unowned let dataSource: LoginCursorDataSource

    init(profile: Profile, dataSource: LoginCursorDataSource) {
        self.profile = profile
        self.dataSource = dataSource
        super.init()
    }

    @objc func searchInputView(searchView: SearchInputView, didChangeTextTo text: String) {
        searchLoginsWithText(text)
    }

    @objc func searchInputViewDidClose(searchView: SearchInputView) {
        activeSearchDeferred = profile.logins.getAllLogins()
            .bindQueue(dispatch_get_main_queue(), f: reloadTableWithResult)
    }

    private func searchLoginsWithText(text: String) -> Success {
        activeSearchDeferred = profile.logins.searchLoginsWithQuery(text)
            .bindQueue(dispatch_get_main_queue(), f: reloadTableWithResult)
        return activeSearchDeferred!
    }

    private func reloadTableWithResult(result: Maybe<Cursor<LoginData>>) -> Success {
        self.dataSource.cursor = result.successValue
        self.dataSource.tableView.reloadData()
        self.activeSearchDeferred = nil
        return succeed()
    }
}

/// Data source for handling LoginData objects from a Cursor
private class LoginCursorDataSource: NSObject, UITableViewDataSource {

    private unowned let tableView: UITableView

    private let LoginCellIdentifier = "LoginCell"

    var cursor: Cursor<LoginData>?

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)
    }

    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionIndexTitlesForTableView(tableView)?.count ?? 0
    }

    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loginsForSection(section).count
    }

    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell

        let login = loginsForSection(indexPath.section)[indexPath.row]
        cell.style = .IconAndBothLabels
        cell.updateCellWithLogin(login)
        return cell
    }

    @objc func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard cursor?.count > 0 else {
            return nil
        }

        var firstHostnameCharacters = [Character]()
        cursor?.forEach { login in
            guard let login = login, let host = login.hostname.asURL?.host else {
                return
            }

            let firstChar = host.uppercaseString[host.startIndex]
            if !firstHostnameCharacters.contains(firstChar) {
                firstHostnameCharacters.append(firstChar)
            }
        }
        return firstHostnameCharacters.map { String($0) }
    }

    @objc func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        guard let titles = sectionIndexTitlesForTableView(tableView) where index < titles.count && index >= 0 else {
            return 0
        }
        return titles.indexOf(title) ?? 0
    }

    @objc func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIndexTitlesForTableView(tableView)?[section]
    }

    private func loginsForSection(section: Int) -> [LoginData] {
        guard let sectionTitles = sectionIndexTitlesForTableView(tableView) else {
            return []
        }

        let titleForSectionAtIndex = sectionTitles[section]
        let logins = cursor?.filter { $0?.hostname.asURL?.host?.uppercaseString.startsWith(titleForSectionAtIndex) ?? false }
        return logins?.flatMap { $0 } ?? []
    }
}
