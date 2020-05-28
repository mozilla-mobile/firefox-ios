/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Storage
import Shared
import SwiftKeychainWrapper

private struct LoginListUX {
    static let RowHeight: CGFloat = 58
    static let SearchHeight: CGFloat = 58
    static let selectionButtonFont = UIFont.systemFont(ofSize: 16)
    static let NoResultsFont = UIFont.systemFont(ofSize: 16)
    static let NoResultsTextColor = UIColor.Photon.Grey40
}

private extension UITableView {
    var allLoginIndexPaths: [IndexPath] {
        return ((LoginsSettingsSection + 1)..<self.numberOfSections).flatMap { sectionNum in
            (0..<self.numberOfRows(inSection: sectionNum)).map {
                IndexPath(row: $0, section: sectionNum)
            }
        }
    }
}

private let CellReuseIdentifier = "cell-reuse-id"
private let SectionHeaderId = "section-header-id"
private let LoginsSettingsSection = 0

class LoginListViewController: SensitiveViewController {

    fileprivate lazy var loginSelectionController: ListSelectionController = {
        return ListSelectionController(tableView: self.tableView)
    }()

    fileprivate lazy var loginDataSource: LoginDataSource = {
        let dataSource = LoginDataSource(profile: profile, searchController: searchController)
        dataSource.dataObserver = self
        return dataSource
    }()

    fileprivate let profile: Profile
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var activeLoginQuery: Deferred<Maybe<[LoginRecord]>>?
    fileprivate let loadingView = SettingsLoadingView()
    fileprivate var deleteAlert: UIAlertController?
    fileprivate var selectionButtonHeightConstraint: Constraint?
    fileprivate var selectedIndexPaths = [IndexPath]()
    fileprivate let tableView = UITableView()

    weak var settingsDelegate: SettingsDelegate?
    var shownFromAppMenu: Bool = false

    // Titles for selection/deselect/delete buttons
    fileprivate let deselectAllTitle = NSLocalizedString("Deselect All", tableName: "LoginManager", comment: "Label for the button used to deselect all logins.")
    fileprivate let selectAllTitle = NSLocalizedString("Select All", tableName: "LoginManager", comment: "Label for the button used to select all logins.")
    fileprivate let deleteLoginTitle = NSLocalizedString("Delete", tableName: "LoginManager", comment: "Label for the button used to delete the current login.")

    fileprivate lazy var selectionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = LoginListUX.selectionButtonFont
        button.addTarget(self, action: #selector(tappedSelectionButton), for: .touchUpInside)
        return button
    }()

    static func shouldShowAppMenuShortcut(forPrefs prefs: Prefs) -> Bool {
        // default to on
        return prefs.boolForKey(PrefsKeys.LoginsShowShortcutMenuItem) ?? true
    }

    static func create(authenticateInNavigationController navigationController: UINavigationController, profile: Profile, settingsDelegate: SettingsDelegate) -> Deferred<LoginListViewController?> {
        let deferred = Deferred<LoginListViewController?>()

        func fillDeferred(ok: Bool) {
            if ok {
                LeanPlumClient.shared.track(event: .openedLogins)
                let viewController = LoginListViewController(profile: profile)
                viewController.settingsDelegate = settingsDelegate
                deferred.fill(viewController)
            } else {
                deferred.fill(nil)
            }
        }

        guard let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo(), authInfo.requiresValidation() else {
            fillDeferred(ok: true)
            return deferred
        }

        AppAuthenticator.presentAuthenticationUsingInfo(authInfo, touchIDReason: AuthenticationStrings.loginsTouchReason, success: {
            fillDeferred(ok: true)
        }, cancel: {
            fillDeferred(ok: false)
        }, fallback: {
            AppAuthenticator.presentPasscodeAuthentication(navigationController).uponQueue(.main) { isOk in
                if isOk {
                    // In the success case of the passcode dialog, it requires explicit dismissal to continue
                    navigationController.dismiss(animated: true)
                }

                fillDeferred(ok: isOk)
            }
        })

        return deferred
    }

    private init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = Strings.LoginsAndPasswordsTitle
        tableView.register(ThemedTableViewCell.self, forCellReuseIdentifier: CellReuseIdentifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderId)

        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        // Setup the Search Controller
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = Strings.LoginsListSearchPlaceholder
        searchController.delegate = self
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
        // No need to hide the navigation bar on iPad to make room, and hiding makes the search bar too close to the top
        searchController.hidesNavigationBarDuringPresentation = UIDevice.current.userInterfaceIdiom != .pad

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(remoteLoginsDidChange), name: .DataRemoteLoginChangesWereApplied, object: nil)
        notificationCenter.addObserver(self, selector: #selector(dismissAlertController), name: UIApplication.didEnterBackgroundNotification, object: nil)

        setupDefaultNavButtons()
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(selectionButton)
        loadingView.isHidden = true

        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalTo(self.selectionButton.snp.top)
        }

        selectionButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalTo(self.tableView.snp.bottom)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
            selectionButtonHeightConstraint = make.height.equalTo(0).constraint
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }

        applyTheme()

        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadLogins()
    }

    func applyTheme() {
        view.backgroundColor = UIColor.theme.tableView.headerBackground

        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
        tableView.reloadData()

        (tableView.tableHeaderView as? Themeable)?.applyTheme()

        selectionButton.setTitleColor(UIColor.theme.tableView.rowBackground, for: [])
        selectionButton.backgroundColor = UIColor.theme.general.highlightBlue

        let isDarkTheme = ThemeManager.instance.currentName == .dark
        var searchTextField: UITextField?
        if #available(iOS 13.0, *) {
            searchTextField = searchController.searchBar.searchTextField
        } else {
            searchTextField = searchController.searchBar.value(forKey: "searchField") as? UITextField
        }
        // Theme the search text field (Dark / Light)
        if isDarkTheme {
            searchTextField?.defaultTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
        } else {
            searchTextField?.defaultTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.black
        }
        // Theme the glass icon next to the search text field
        if let glassIconView = searchTextField?.leftView as? UIImageView {
            //Magnifying glass
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = UIColor.theme.tableView.headerTextLight
        }
    }

    @objc func dismissLogins() {
        dismiss(animated: true)
    }

    fileprivate func setupDefaultNavButtons() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))
        if shownFromAppMenu {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissLogins))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    fileprivate func toggleDeleteBarButton() {
        // Show delete bar button item if we have selected any items
        if loginSelectionController.selectedCount > 0 {
            if navigationItem.rightBarButtonItem == nil {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: deleteLoginTitle, style: .plain, target: self, action: #selector(tappedDelete))
                navigationItem.rightBarButtonItem?.tintColor = UIColor.Photon.Red50
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    fileprivate func toggleSelectionTitle() {
        if loginSelectionController.selectedCount == loginDataSource.count {
            selectionButton.setTitle(deselectAllTitle, for: [])
        } else {
            selectionButton.setTitle(selectAllTitle, for: [])
        }
    }

    // Wrap the SQLiteLogins method to allow us to cancel it from our end.
    fileprivate func queryLogins(_ query: String) -> Deferred<Maybe<[LoginRecord]>> {
        let deferred = Deferred<Maybe<[LoginRecord]>>()
        profile.logins.searchLoginsWithQuery(query) >>== { logins in
            deferred.fillIfUnfilled(Maybe(success: logins.asArray()))
            succeed()
        }
        return deferred
    }
}

extension LoginListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        loadLogins(query)
    }
}

fileprivate var isDuringSearchControllerDismiss = false

extension LoginListViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        isDuringSearchControllerDismiss = true
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        isDuringSearchControllerDismiss = false
    }
}

// MARK: - Selectors
private extension LoginListViewController {
    @objc func remoteLoginsDidChange() {
        DispatchQueue.main.async {
            self.loadLogins()
        }
    }

    @objc func dismissAlertController() {
        self.deleteAlert?.dismiss(animated: false, completion: nil)
    }

    func loadLogins(_ query: String? = nil) {
        loadingView.isHidden = false

        // Fill in an in-flight query and re-query
        activeLoginQuery?.fillIfUnfilled(Maybe(success: []))
        activeLoginQuery = queryLogins(query ?? "")
        activeLoginQuery! >>== loginDataSource.setLogins
    }

    @objc func beginEditing() {
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelection))
        selectionButtonHeightConstraint?.update(offset: UIConstants.ToolbarHeight)
        selectionButton.setTitle(selectAllTitle, for: [])
        self.view.layoutIfNeeded()
        tableView.setEditing(true, animated: true)
        tableView.reloadData()
    }

    @objc func cancelSelection() {
        // Update selection and select all button
        loginSelectionController.deselectAll()
        toggleSelectionTitle()
        selectionButtonHeightConstraint?.update(offset: 0)
        selectionButton.setTitle(nil, for: [])
        self.view.layoutIfNeeded()

        tableView.setEditing(false, animated: true)
        setupDefaultNavButtons()
        tableView.reloadData()
    }

    @objc func tappedDelete() {
        profile.logins.hasSyncedLogins().uponQueue(.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                // Delete here
                let guidsToDelete = self.loginSelectionController.selectedIndexPaths.compactMap { indexPath in
                    self.loginDataSource.loginAtIndexPath(indexPath)?.id
                }

                self.profile.logins.delete(ids: guidsToDelete).uponQueue(.main) { _ in
                    self.cancelSelection()
                    self.loadLogins()
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    @objc func tappedSelectionButton() {
        // If we haven't selected everything yet, select all
        if loginSelectionController.selectedCount < loginDataSource.count {
            // Find all unselected indexPaths
            let unselectedPaths = tableView.allLoginIndexPaths.filter { indexPath in
                return !loginSelectionController.indexPathIsSelected(indexPath)
            }
            loginSelectionController.selectIndexPaths(unselectedPaths)
            unselectedPaths.forEach { indexPath in
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }

        // If everything has been selected, deselect all
        else {
            loginSelectionController.deselectAll()
            tableView.allLoginIndexPaths.forEach { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }

        toggleSelectionTitle()
        toggleDeleteBarButton()
    }
}

// MARK: - LoginDataSourceObserver
extension LoginListViewController: LoginDataSourceObserver {
    func loginSectionsDidUpdate() {
        loadingView.isHidden = true
        tableView.reloadData()
        activeLoginQuery = nil
        navigationItem.rightBarButtonItem?.isEnabled = loginDataSource.count > 0
        restoreSelectedRows()
    }

    func restoreSelectedRows() {
        for path in self.loginSelectionController.selectedIndexPaths {
            tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        }
    }
}

// MARK: - UITableViewDelegate
extension LoginListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Headers are hidden except for the first login section, which has a title (see also viewForHeaderInSection)
        return section == 1 ? 44 : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Only the start of the logins list gets a title
        if section != 1 {
            return nil
        }
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderId) as? ThemedTableSectionHeaderFooterView else {
            return nil
        }
        headerView.titleLabel.text = Strings.LoginsListTitle
        // not using a grouped table: show header borders
        headerView.showBorder(for: .top, true)
        headerView.showBorder(for: .bottom, true)
        headerView.applyTheme()
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == LoginsSettingsSection, searchController.isActive || tableView.isEditing {
            return 0
        }
        return indexPath.section == LoginsSettingsSection ? 44 : LoginListUX.RowHeight
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            loginSelectionController.selectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        } else if let login = loginDataSource.loginAtIndexPath(indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let detailViewController = LoginDetailViewController(profile: profile, login: login)
            detailViewController.settingsDelegate = settingsDelegate
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            loginSelectionController.deselectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        }
    }
}

// MARK: - KeyboardHelperDelegate
extension LoginListViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - SearchInputViewDelegate
extension LoginListViewController: SearchInputViewDelegate {

    @objc func searchInputView(_ searchView: SearchInputView, didChangeTextTo text: String) {
        loadLogins(text)
    }

    @objc func searchInputViewBeganEditing(_ searchView: SearchInputView) {
        // Trigger a cancel for editing
        cancelSelection()

        // Hide the edit button while we're searching
        navigationItem.rightBarButtonItem = nil
        loadLogins()
    }

    @objc func searchInputViewFinishedEditing(_ searchView: SearchInputView) {
        setupDefaultNavButtons()
        loadLogins()
    }
}

/// Controller that keeps track of selected indexes
fileprivate class ListSelectionController: NSObject {
    private unowned let tableView: UITableView
    private(set) var selectedIndexPaths = [IndexPath]()

    var selectedCount: Int {
        return selectedIndexPaths.count
    }

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
    }

    func selectIndexPath(_ indexPath: IndexPath) {
        selectedIndexPaths.append(indexPath)
    }

    func indexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return selectedIndexPaths.contains(indexPath) { path1, path2 in
            return path1.row == path2.row && path1.section == path2.section
        }
    }

    func deselectIndexPath(_ indexPath: IndexPath) {
        guard let foundSelectedPath = (selectedIndexPaths.filter { $0.row == indexPath.row && $0.section == indexPath.section }).first,
              let indexToRemove = selectedIndexPaths.firstIndex(of: foundSelectedPath) else {
            return
        }

        selectedIndexPaths.remove(at: indexToRemove)
    }

    func deselectAll() {
        selectedIndexPaths.removeAll()
    }

    func selectIndexPaths(_ indexPaths: [IndexPath]) {
        selectedIndexPaths += indexPaths
    }
}

protocol LoginDataSourceObserver: AnyObject {
    func loginSectionsDidUpdate()
}

/// Data source for handling LoginData objects from a Cursor
class LoginDataSource: NSObject, UITableViewDataSource {
    var count = 0
    weak var dataObserver: LoginDataSourceObserver?
    weak var searchController: UISearchController?
    fileprivate let emptyStateView = NoLoginsView()
    fileprivate var titles = [Character]()

    let boolSettings: (BoolSetting, BoolSetting)

    init(profile: Profile, searchController: UISearchController) {
        self.searchController = searchController
        boolSettings = (
            BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.LoginsSaveEnabled, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingToSaveLogins)),
            BoolSetting(prefs: profile.prefs, prefKey: PrefsKeys.LoginsShowShortcutMenuItem, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingToShowLoginsInAppMenu)))
        super.init()
    }

    fileprivate var loginRecordSections = [Character: [LoginRecord]]() {
        didSet {
            assert(Thread.isMainThread)
            self.dataObserver?.loginSectionsDidUpdate()
        }
    }

    fileprivate func loginsForSection(_ section: Int) -> [LoginRecord]? {
        guard section > 0 else {
            assertionFailure()
            return nil
        }
        let titleForSectionIndex = titles[section - 1]
        return loginRecordSections[titleForSectionIndex]
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

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        if  loginRecordSections.isEmpty {
            tableView.backgroundView = emptyStateView
            return 1
        }

        tableView.backgroundView = nil
        // Add one section for the settings section.
        return loginRecordSections.count + 1
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == LoginsSettingsSection {
            return 2
        }
        return loginsForSection(section)?.count ?? 0
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: CellReuseIdentifier)

        if indexPath.section == LoginsSettingsSection {
            let hideSettings = searchController?.isActive ?? false || tableView.isEditing
            let setting = indexPath.row == 0 ? boolSettings.0 : boolSettings.1
            setting.onConfigureCell(cell)
            if hideSettings {
                cell.isHidden = true
            }

            // Fade in the cell while dismissing the search or the cell showing suddenly looks janky
            if isDuringSearchControllerDismiss {
                cell.isHidden = false
                cell.contentView.alpha = 0
                cell.accessoryView?.alpha = 0
                UIView.animate(withDuration: 0.6) {
                    cell.contentView.alpha = 1
                    cell.accessoryView?.alpha = 1
                }
            }
        } else {
            guard let login = loginAtIndexPath(indexPath) else { return cell }
            cell.textLabel?.text = login.hostname
            cell.detailTextColor = UIColor.theme.tableView.rowDetailText
            cell.detailTextLabel?.text = login.username
            cell.accessoryType = .disclosureIndicator
        }
        
        // Need to override the default background multi-select color to support theming
        cell.multipleSelectionBackgroundView = UIView()
        cell.applyTheme()
        return cell
    }

    func setLogins(_ logins: [LoginRecord]) {
        // NB: Make sure we call the callback on the main thread so it can be synced up with a reloadData to
        //     prevent race conditions between data/UI indexing.
        return computeSectionsFromLogins(logins).uponQueue(.main) { result in
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

    fileprivate func computeSectionsFromLogins(_ logins: [LoginRecord]) -> Deferred<Maybe<([Character], [Character: [LoginRecord]])>> {
        guard logins.count > 0 else {
            return deferMaybe( ([Character](), [Character: [LoginRecord]]()) )
        }

        var domainLookup = [GUID: (baseDomain: String?, host: String?, hostname: String)]()
        var sections = [Character: [LoginRecord]]()
        var titleSet = Set<Character>()

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

        return deferDispatchAsync(DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass)) {
            // Precompute the baseDomain, host, and hostname values for sorting later on. At the moment
            // baseDomain() is a costly call because of the ETLD lookup tables.
            logins.forEach { login in
                domainLookup[login.id] = (
                    login.hostname.asURL?.baseDomain,
                    login.hostname.asURL?.host,
                    login.hostname
                )
            }

            // 1. Temporarily insert titles into a Set to get duplicate removal for 'free'.
            logins.forEach { titleSet.insert(titleForLogin($0)) }

            // 2. Setup an empty list for each title found.
            titleSet.forEach { sections[$0] = [LoginRecord]() }

            // 3. Go through our logins and put them in the right section.
            logins.forEach { sections[titleForLogin($0)]?.append($0) }

            // 4. Go through each section and sort.
            sections.forEach { sections[$0] = $1.sorted(by: sortByDomain) }

            return deferMaybe( (Array(titleSet).sorted(), sections) )
        }
    }
}

// Empty state view when there is no logins to display.
fileprivate class NoLoginsView: UIView {

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
        label.text = NSLocalizedString("No logins found", tableName: "LoginManager", comment: "Label displayed when no logins are found after searching.")
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
    }

    fileprivate override func updateConstraints() {
        super.updateConstraints()
        titleLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
