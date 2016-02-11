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
    static let selectionButtonFont = UIFont.systemFontOfSize(16)
    static let selectionButtonTextColor = UIColor.whiteColor()
    static let selectionButtonBackground = UIConstants.HighlightBlue
    static let NoResultsFont: UIFont = UIFont.systemFontOfSize(16)
    static let NoResultsTextColor: UIColor = UIColor.lightGrayColor()
}

private extension UITableView {
    var allIndexPaths: [NSIndexPath] {
        return (0..<self.numberOfSections).flatMap { sectionNum in
            (0..<self.numberOfRowsInSection(sectionNum)).map { NSIndexPath(forRow: $0, inSection: sectionNum) }
        }
    }
}

private let LoginCellIdentifier = "LoginCell"

class LoginListViewController: UIViewController {

    private lazy var loginSelectionController: ListSelectionController = {
        return ListSelectionController(tableView: self.tableView)
    }()

    private lazy var loginDataSource: LoginCursorDataSource = {
        return LoginCursorDataSource()
    }()

    private let profile: Profile

    private let searchView = SearchInputView()

    private var activeLoginQuery: Success?

    private let loadingStateView = LoadingLoginsView()

    // Titles for selection/deselect buttons
    private let deselectAllTitle = NSLocalizedString("Deselect All", tableName: "LoginManager", comment: "Title for deselecting all selected logins")
    private let selectAllTitle = NSLocalizedString("Select All", tableName: "LoginManager", comment: "Title for selecting all logins")

    private lazy var selectionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = LoginListUX.selectionButtonFont
        button.setTitle(self.selectAllTitle, forState: .Normal)
        button.setTitleColor(LoginListUX.selectionButtonTextColor, forState: .Normal)
        button.backgroundColor = LoginListUX.selectionButtonBackground
        button.addTarget(self, action: "SELdidTapSelectionButton", forControlEvents: .TouchUpInside)
        return button
    }()

    private var selectionButtonHeightConstraint: Constraint?
    private var selectedIndexPaths = [NSIndexPath]()

    private let tableView = UITableView()

    weak var settingsDelegate: SettingsDelegate?

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: Selector("SELreloadLogins"), name: NotificationDataRemoteLoginChangesWereApplied, object: nil)

        automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.whiteColor()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")

        self.title = NSLocalizedString("Logins", tableName: "LoginManager", comment: "Title for Logins List View screen")

        searchView.delegate = self
        tableView.registerClass(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)

        view.addSubview(searchView)
        view.addSubview(tableView)
        view.addSubview(loadingStateView)
        view.addSubview(selectionButton)

        loadingStateView.hidden = true

        searchView.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom).constraint
            make.left.right.equalTo(self.view)
            make.height.equalTo(LoginListUX.SearchHeight)
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(searchView.snp_bottom)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.selectionButton.snp_top)
        }

        selectionButton.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
            make.top.equalTo(self.tableView.snp_bottom)
            make.bottom.equalTo(self.view)
            selectionButtonHeightConstraint = make.height.equalTo(0).constraint
        }

        loadingStateView.snp_makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchView.isEditing ? loadLogins(searchView.inputField.text) : loadLogins()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.loginDataSource.emptyStateView.searchBarHeight = searchView.frame.height
        self.loadingStateView.searchBarHeight = searchView.frame.height
    }

    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.removeObserver(self, name: NotificationDataLoginDidChange, object: nil)
    }

    private func toggleDeleteBarButton() {
        // Show delete bar button item if we have selected any items
        if loginSelectionController.selectedCount > 0 {
            if (navigationItem.rightBarButtonItem == nil) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: "SELdelete")
                navigationItem.rightBarButtonItem?.tintColor = UIColor.redColor()
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func toggleSelectionTitle() {
        if loginSelectionController.selectedCount == loginDataSource.cursor?.count {
            selectionButton.setTitle(deselectAllTitle, forState: .Normal)
        } else {
            selectionButton.setTitle(selectAllTitle, forState: .Normal)
        }
    }

    private func loadLogins(query: String? = nil) -> Success {
        loadingStateView.hidden = false
        let query = profile.logins.searchLoginsWithQuery(query).bindQueue(dispatch_get_main_queue(), f: reloadTableWithResult)
        activeLoginQuery = query
        return query
    }

    private func reloadTableWithResult(result: Maybe<Cursor<Login>>) -> Success {
        loadingStateView.hidden = true
        loginDataSource.cursor = result.successValue
        tableView.reloadData()
        activeLoginQuery = nil

        if loginDataSource.cursor?.count > 0 {
            navigationItem.rightBarButtonItem?.enabled = true
        } else {
            navigationItem.rightBarButtonItem?.enabled = false
        }

        return succeed()
    }
}

// MARK: - Selectors
extension LoginListViewController {

    func SELreloadLogins() {
        loadLogins()
    }

    func SELedit() {
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "SELcancel")
        selectionButtonHeightConstraint?.updateOffset(UIConstants.ToolbarHeight)
        self.view.layoutIfNeeded()
        tableView.setEditing(true, animated: true)
    }

    func SELcancel() {
        // Update selection and select all button
        loginSelectionController.deselectAll()
        toggleSelectionTitle()
        selectionButtonHeightConstraint?.updateOffset(0)
        self.view.layoutIfNeeded()

        tableView.setEditing(false, animated: true)
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")
    }

    func SELdelete() {
        profile.logins.hasSyncedLogins().uponQueue(dispatch_get_main_queue()) { yes in
            let deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                // Delete here
                let guidsToDelete = self.loginSelectionController.selectedIndexPaths.map { indexPath in
                    self.loginDataSource.loginAtIndexPath(indexPath).guid
                }

                self.profile.logins.removeLoginsWithGUIDs(guidsToDelete).uponQueue(dispatch_get_main_queue()) { _ in
                    self.SELcancel()
                    self.loadLogins()
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.presentViewController(deleteAlert, animated: true, completion: nil)
        }
    }

    func SELdidTapSelectionButton() {
        // If we haven't selected everything yet, select all
        if loginSelectionController.selectedCount < loginDataSource.cursor?.count {
            // Find all unselected indexPaths
            let unselectedPaths = tableView.allIndexPaths.filter { indexPath in
                return !loginSelectionController.indexPathIsSelected(indexPath)
            }
            loginSelectionController.selectIndexPaths(unselectedPaths)
            unselectedPaths.forEach { indexPath in
                self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }
        }

        // If everything has been selected, deselect all
        else {
            loginSelectionController.deselectAll()
            tableView.allIndexPaths.forEach { indexPath in
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }

        toggleSelectionTitle()
        toggleDeleteBarButton()
    }
}

// MARK: - UITableViewDelegate
extension LoginListViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Force the headers to be hidden
        return 0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return LoginListUX.RowHeight
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            loginSelectionController.selectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            let login = loginDataSource.loginAtIndexPath(indexPath)
            let detailViewController = LoginDetailViewController(profile: profile, login: login)
            detailViewController.settingsDelegate = settingsDelegate
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            loginSelectionController.deselectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        }
    }
}

// MARK: - KeyboardHelperDelegate
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

// MARK: - SearchInputViewDelegate
extension LoginListViewController: SearchInputViewDelegate {

    @objc func searchInputView(searchView: SearchInputView, didChangeTextTo text: String) {
        loadLogins(text)
    }

    @objc func searchInputViewBeganEditing(searchView: SearchInputView) {
        // Trigger a cancel for editing
        SELcancel()

        // Hide the edit button while we're searching
        navigationItem.rightBarButtonItem = nil
        loadLogins()
    }

    @objc func searchInputViewFinishedEditing(searchView: SearchInputView) {
        // Show the edit after we're done with the search
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "SELedit")
        loadLogins()
    }
}

/// Controller that keeps track of selected indexes
private class ListSelectionController: NSObject {

    private unowned let tableView: UITableView

    private(set) var selectedIndexPaths = [NSIndexPath]()

    var selectedCount: Int {
        return selectedIndexPaths.count
    }

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
    }

    func selectIndexPath(indexPath: NSIndexPath) {
        selectedIndexPaths.append(indexPath)
    }

    func indexPathIsSelected(indexPath: NSIndexPath) -> Bool {
        return selectedIndexPaths.contains(indexPath) { path1, path2 in
            return path1.row == path2.row && path1.section == path2.section
        }
    }

    func deselectIndexPath(indexPath: NSIndexPath) {
        guard let foundSelectedPath = (selectedIndexPaths.filter { $0.row == indexPath.row && $0.section == indexPath.section }).first,
              let indexToRemove = selectedIndexPaths.indexOf(foundSelectedPath) else {
            return
        }

        selectedIndexPaths.removeAtIndex(indexToRemove)
    }

    func deselectAll() {
        selectedIndexPaths.removeAll()
    }

    func selectIndexPaths(indexPaths: [NSIndexPath]) {
        selectedIndexPaths += indexPaths
    }
}

/// Data source for handling LoginData objects from a Cursor
private class LoginCursorDataSource: NSObject, UITableViewDataSource {

    private let emptyStateView = NoLoginsView()

    var cursor: Cursor<Login>?

    func loginAtIndexPath(indexPath: NSIndexPath) -> Login {
        return loginsForSection(indexPath.section)[indexPath.row]
    }

    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let numOfSections = sectionIndexTitles()?.count ?? 0
        if numOfSections == 0 {
            tableView.backgroundView = emptyStateView
            tableView.separatorStyle = .None
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
        return numOfSections
    }

    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loginsForSection(section).count
    }

    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LoginCellIdentifier, forIndexPath: indexPath) as! LoginTableViewCell

        let login = loginAtIndexPath(indexPath)
        cell.style = .NoIconAndBothLabels
        cell.updateCellWithLogin(login)

        return cell
    }

    @objc func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return sectionIndexTitles()
    }

    @objc func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        guard let titles = sectionIndexTitles() where index < titles.count && index >= 0 else {
            return 0
        }
        return titles.indexOf(title) ?? 0
    }

    @objc func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIndexTitles()?[section]
    }

    private func sectionIndexTitles() -> [String]? {
        guard cursor?.count > 0 else {
            return nil
        }

        var firstHostnameCharacters = [Character]()
        cursor?.forEach { login in
            guard let login = login, let baseDomain = login.hostname.asURL?.baseDomain() else {
                return
            }

            let firstChar = baseDomain.uppercaseString[baseDomain.startIndex]
            if !firstHostnameCharacters.contains(firstChar) {
                firstHostnameCharacters.append(firstChar)
            }
        }
        let sectionTitles = firstHostnameCharacters.map { String($0) }
        return sectionTitles.sort()
    }

    private func loginsForSection(section: Int) -> [Login] {
        guard let sectionTitles = sectionIndexTitles() else {
            return []
        }

        let titleForSectionAtIndex = sectionTitles[section]
        let logins = cursor?.filter { $0?.hostname.asURL?.baseDomain()?.uppercaseString.startsWith(titleForSectionAtIndex) ?? false }
        let flattenLogins = logins?.flatMap { $0 } ?? []
        return flattenLogins.sort { login1, login2 in
            let baseDomain1 = login1.hostname.asURL?.baseDomain()
            let baseDomain2 = login2.hostname.asURL?.baseDomain()
            let host1 = login1.hostname.asURL?.host
            let host2 = login2.hostname.asURL?.host

            if baseDomain1 == baseDomain2 {
                return host1 < host2
            } else {
                return baseDomain1 < baseDomain2
            }
        }
    }
}

/// Empty state view when there is no logins to display.
private class NoLoginsView: UIView {

    // We use the search bar height to maintain visual balance with the whitespace on this screen. The
    // title label is centered visually using the empty view + search bar height as the size to center with.
    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LoginListUX.NoResultsFont
        label.textColor = LoginListUX.NoResultsTextColor
        label.text = NSLocalizedString("No logins found", tableName: "LoginManager", comment: "Title displayed when no logins are found after searching")
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
    }

    private override func updateConstraints() {
        super.updateConstraints()
        titleLabel.snp_remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to display to the user while we are loading the logins
private class LoadingLoginsView: UIView {

    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicator.hidesWhenStopped = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        backgroundColor = UIColor.whiteColor()
        indicator.startAnimating()
    }

    private override func updateConstraints() {
        super.updateConstraints()
        indicator.snp_remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
