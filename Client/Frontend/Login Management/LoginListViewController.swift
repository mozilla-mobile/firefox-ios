// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared

private extension UITableView {
    var allLoginIndexPaths: [IndexPath] {
        return ((LoginsSettingsSection + 1)..<self.numberOfSections).flatMap { sectionNum in
            (0..<self.numberOfRows(inSection: sectionNum)).map {
                IndexPath(row: $0, section: sectionNum)
            }
        }
    }
}

let CellReuseIdentifier = "cell-reuse-id"
let SectionHeaderId = "section-header-id"
let LoginsSettingsSection = 0

class LoginListViewController: SensitiveViewController {

    private let viewModel: LoginListViewModel

    fileprivate lazy var loginSelectionController: LoginListSelectionHelper = {
        return LoginListSelectionHelper(tableView: self.tableView)
    }()

    fileprivate var loginDataSource: LoginDataSource
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate let loadingView: SettingsLoadingView = .build()
    fileprivate var deleteAlert: UIAlertController?
    fileprivate var selectionButtonHeightConstraint: NSLayoutConstraint?
    fileprivate var selectedIndexPaths = [IndexPath]()
    fileprivate let tableView: UITableView = .build()

    weak var settingsDelegate: SettingsDelegate?
    var shownFromAppMenu: Bool = false
    var webpageNavigationHandler: ((_ url: URL?) -> Void)?

    fileprivate lazy var selectionButton: UIButton = .build { button in
        button.titleLabel?.font = LoginListViewModel.LoginListUX.selectionButtonFont
        button.addTarget(self, action: #selector(self.tappedSelectionButton), for: .touchUpInside)
    }

    static func shouldShowAppMenuShortcut(forPrefs prefs: Prefs) -> Bool {
        // default to on
        return prefs.boolForKey(PrefsKeys.LoginsShowShortcutMenuItem) ?? true
    }

    static func create(authenticateInNavigationController navigationController: UINavigationController, profile: Profile, settingsDelegate: SettingsDelegate, webpageNavigationHandler: ((_ url: URL?) -> Void)?) -> Deferred<LoginListViewController?> {
        let deferred = Deferred<LoginListViewController?>()

        func fillDeferred(ok: Bool) {
            if ok {
                let viewController = LoginListViewController(profile: profile, webpageNavigationHandler: webpageNavigationHandler)
                viewController.settingsDelegate = settingsDelegate
                deferred.fill(viewController)
            } else {
                deferred.fill(nil)
            }
        }
        
        AppAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
            switch result {
                case .success():
                    fillDeferred(ok: true)
                case .failure(_):
                    fillDeferred(ok: false)
            }
        }

        return deferred
    }

    private init(profile: Profile, webpageNavigationHandler: ((_ url: URL?) -> Void)?) {
        self.viewModel = LoginListViewModel(profile: profile, searchController: searchController)
        self.loginDataSource = LoginDataSource(viewModel: self.viewModel)
        self.webpageNavigationHandler = webpageNavigationHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .LoginsAndPasswordsTitle
        tableView.register(ThemedTableViewCell.self, forCellReuseIdentifier: CellReuseIdentifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderId)

        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        if #available(iOS 15.0, *) {
             tableView.sectionHeaderTopPadding = 0
         }

        // Setup the Search Controller
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = .LoginsListSearchPlaceholder
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

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: selectionButton.topAnchor),

            selectionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            selectionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            selectionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            selectionButton.topAnchor.constraint(equalTo: tableView.bottomAnchor),

            loadingView.topAnchor.constraint(equalTo: tableView.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            loadingView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor)
        ])

        selectionButtonHeightConstraint = selectionButton.heightAnchor.constraint(equalToConstant: 0)
        selectionButtonHeightConstraint?.isActive = true

        applyTheme()

        KeyboardHelper.defaultHelper.addDelegate(self)
        viewModel.delegate = self
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

        (tableView.tableHeaderView as? NotificationThemeable)?.applyTheme()

        selectionButton.setTitleColor(UIColor.theme.tableView.rowBackground, for: [])
        selectionButton.backgroundColor = UIColor.theme.general.highlightBlue

        let isDarkTheme = LegacyThemeManager.instance.currentName == .dark
        let searchTextField = searchController.searchBar.searchTextField
        
        // Theme the search text field (Dark / Light)
        if isDarkTheme {
            searchTextField.defaultTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
        } else {
            searchTextField.defaultTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.black
        }
        // Theme the glass icon next to the search text field
        if let glassIconView = searchTextField.leftView as? UIImageView {
            //Magnifying glass
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = UIColor.theme.tableView.headerTextLight
        }
    }

    @objc func dismissLogins() {
        dismiss(animated: true)
    }
    lazy var editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))
    lazy var addCredentialButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(presentAddCredential))
    lazy var deleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .LoginListDelete, style: .plain, target: self, action: #selector(tappedDelete))
        button.tintColor = UIColor.Photon.Red50
        return button
    }()
    lazy var cancelSelectionButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelection))

    fileprivate func setupDefaultNavButtons() {
         navigationItem.rightBarButtonItems = [editButton, addCredentialButton]
        
        if shownFromAppMenu {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissLogins))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    fileprivate func toggleDeleteBarButton() {
        // Show delete bar button item if we have selected any items
        if loginSelectionController.selectedCount > 0 {
            if navigationItem.rightBarButtonItems == nil {
                navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }

    fileprivate func toggleSelectionTitle() {
        let areAllSelected = loginSelectionController.selectedCount == viewModel.count
        selectionButton.setTitle(areAllSelected ? .LoginListDeselctAll : .LoginListSelctAll, for: [])
    }
}

extension LoginListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        loadLogins(query)
    }
}

extension LoginListViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.setIsDuringSearchControllerDismiss(to: true)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        viewModel.setIsDuringSearchControllerDismiss(to: false)
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
        navigationController?.view.endEditing(true)
    }

    func loadLogins(_ query: String? = nil) {
        loadingView.isHidden = false
        viewModel.loadLogins(query, loginDataSource: self.loginDataSource)
    }

    @objc func beginEditing() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.leftBarButtonItems = [cancelSelectionButton]
        selectionButtonHeightConstraint?.constant = UIConstants.ToolbarHeight
        selectionButton.setTitle(.LoginListSelctAll, for: [])
        self.view.layoutIfNeeded()
        tableView.setEditing(true, animated: true)
        tableView.reloadData()
    }
    
    @objc func presentAddCredential() {
        let addController = AddCredentialViewController() { [weak self] record in
            let result = self?.viewModel.save(loginRecord: record)
            self?.presentedViewController?.dismiss(animated: true) {
                result?.upon { id in
                    DispatchQueue.main.async {
                        self?.loadLogins()
                        self?.tableView.reloadData()
                    }
                }
            }
        }
        
        let controller = UINavigationController(
            rootViewController: addController
        )
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true)
    }

    @objc func cancelSelection() {
        // Update selection and select all button
        loginSelectionController.deselectAll()
        toggleSelectionTitle()
        selectionButtonHeightConstraint?.constant = 0
        selectionButton.setTitle(nil, for: [])
        self.view.layoutIfNeeded()

        tableView.setEditing(false, animated: true)
        setupDefaultNavButtons()
        tableView.reloadData()
    }

    @objc func tappedDelete() {
        viewModel.profile.logins.hasSyncedLogins().uponQueue(.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                // Delete here
                let guidsToDelete = self.loginSelectionController.selectedIndexPaths.compactMap { indexPath in
                    self.viewModel.loginAtIndexPath(indexPath)?.id
                }

                self.viewModel.profile.logins.deleteLogins(ids: guidsToDelete).uponQueue(.main) { _ in
                    self.cancelSelection()
                    self.loadLogins()
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    @objc func tappedSelectionButton() {
        // If we haven't selected everything yet, select all
        if loginSelectionController.selectedCount < viewModel.count {
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

// MARK: - UITableViewDelegate
extension LoginListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Headers are hidden except for the first login section, which has a title (see also viewForHeaderInSection)
        return section == 1 ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Only the start of the logins list gets a title
        if section != 1 {
            return nil
        }
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderId) as? ThemedTableSectionHeaderFooterView else {
            return nil
        }
        headerView.titleLabel.text = .LoginsListTitle
        headerView.titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmall
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
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            loginSelectionController.selectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        } else if let login = viewModel.loginAtIndexPath(indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let detailViewController = LoginDetailViewController(profile: viewModel.profile, login: login, webpageNavigationHandler: webpageNavigationHandler)
            if viewModel.breachIndexPath.contains(indexPath) {
                guard let login = viewModel.loginAtIndexPath(indexPath) else { return }
                let breach = viewModel.breachAlertsManager.breachRecordForLogin(login)
                detailViewController.setBreachRecord(breach: breach)
            }
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

// MARK: - LoginViewModelDelegate
extension LoginListViewController: LoginViewModelDelegate {

    func breachPathDidUpdate() {
        DispatchQueue.main.async {
            self.viewModel.breachIndexPath.forEach {
                guard let cell = self.tableView.cellForRow(at: $0) as? LoginListTableViewCell else { return }
                cell.breachAlertImageView.isHidden = false
                cell.accessibilityValue = "Breached Login Alert"
            }
        }
    }

    func loginSectionsDidUpdate() {
        loadingView.isHidden = true
        tableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.count > 0
        restoreSelectedRows()
    }

    func restoreSelectedRows() {
        for path in self.loginSelectionController.selectedIndexPaths {
            tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        }
    }
}
