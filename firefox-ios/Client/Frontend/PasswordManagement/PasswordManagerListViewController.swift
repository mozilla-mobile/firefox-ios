// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared
import Common

import struct MozillaAppServices.LoginEntry

class PasswordManagerListViewController: SensitiveViewController, Themeable {
    static let loginsSettingsSection = 0

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    private let viewModel: PasswordManagerViewModel

    private var loginDataSource: LoginDataSource
    private let searchController = UISearchController(searchResultsController: nil)
    private let loadingView: SettingsLoadingView = .build()
    private var deleteAlert: UIAlertController?
    private var selectedIndexPaths = [IndexPath]()
    private let tableView: UITableView = .build()
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    weak var coordinator: PasswordManagerFlowDelegate?

    fileprivate lazy var selectionButton: UIButton = .build { button in
        button.titleLabel?.font = PasswordManagerViewModel.UX.selectionButtonFont
        button.addTarget(self, action: #selector(self.tappedSelectionButton), for: .touchUpInside)
    }

    static func shouldShowAppMenuShortcut(forPrefs prefs: Prefs) -> Bool {
        // default to on
        return prefs.boolForKey(PrefsKeys.LoginsShowShortcutMenuItem) ?? true
    }

    init(profile: Profile,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.viewModel = PasswordManagerViewModel(
            profile: profile,
            searchController: searchController,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            loginProvider: profile.logins
        )
        self.loginDataSource = LoginDataSource(viewModel: viewModel)
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        listenForThemeChange(view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .Settings.Passwords.Title
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        tableView.register(cellType: PasswordManagerSettingsTableViewCell.self)
        tableView.register(cellType: PasswordManagerTableViewCell.self)
        tableView.registerHeaderFooter(cellType: ThemedTableSectionHeaderFooterView.self)

        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderTopPadding = 0

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
        notificationCenter.addObserver(self,
                                       selector: #selector(remoteLoginsDidChange),
                                       name: .DataRemoteLoginChangesWereApplied,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(dismissAlertController),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)

        setupDefaultNavButtons()
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(selectionButton)
        loadingView.isHidden = true

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: selectionButton.topAnchor),

            selectionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            selectionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            selectionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            selectionButton.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            selectionButton.heightAnchor.constraint(equalToConstant: UIConstants.ToolbarHeight),

            loadingView.topAnchor.constraint(equalTo: tableView.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            loadingView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor)
        ])

        selectionButton.isHidden = true

        applyTheme()

        KeyboardHelper.defaultHelper.addDelegate(self)
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLogins()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        viewModel.theme = theme
        loginDataSource.viewModel = viewModel

        view.backgroundColor = theme.colors.layer1
        tableView.separatorColor = theme.colors.borderPrimary
        tableView.backgroundColor = theme.colors.layer1

        selectionButton.setTitleColor(theme.colors.textInverted, for: [])
        selectionButton.backgroundColor = theme.colors.actionPrimary
        deleteButton.tintColor = theme.colors.textCritical

        // Search bar text and placeholder color
        let searchTextField = searchController.searchBar.searchTextField
        searchTextField.defaultTextAttributes[NSAttributedString.Key.foregroundColor] = theme.colors.textPrimary
        let placeholderAttribute = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
        searchTextField.attributedPlaceholder = NSAttributedString(string: searchTextField.placeholder ?? "",
                                                                   attributes: placeholderAttribute)

        // Theme the glass icon next to the search text field
        if let glassIconView = searchTextField.leftView as? UIImageView {
            // Magnifying glass
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = theme.colors.iconSecondary
        }
    }

    @objc
    func dismissLogins() {
        dismiss(animated: true)
    }

    func showToast() {
        SimpleToast().showAlertWithText(.LoginListDeleteToast,
                                        bottomContainer: view,
                                        theme: themeManager.getCurrentTheme(for: windowUUID))
    }

    lazy var editButton = UIBarButtonItem(barButtonSystemItem: .edit,
                                          target: self,
                                          action: #selector(beginEditing))

    lazy var addCredentialButton = UIBarButtonItem(barButtonSystemItem: .add,
                                                   target: self,
                                                   action: #selector(presentAddCredential))

    lazy var deleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .LoginListDelete,
                                     style: .plain,
                                     target: self,
                                     action: #selector(tappedDelete))
        return button
    }()

    lazy var cancelSelectionButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                     target: self,
                                                     action: #selector(cancelSelection))

    fileprivate func setupDefaultNavButtons() {
        addCredentialButton.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Passwords.addCredentialButton
        editButton.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Passwords.editButton
        navigationItem.rightBarButtonItems = [editButton, addCredentialButton]
        navigationItem.leftBarButtonItem = nil
    }

    fileprivate func toggleDeleteBarButton() {
        // Show delete bar button item if we have selected any items
        if viewModel.listSelectionHelper.numberOfSelectedCells > 0 {
            if navigationItem.rightBarButtonItems == nil {
                navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }

    fileprivate func toggleSelectionTitle() {
        let areAllSelected = viewModel.listSelectionHelper.numberOfSelectedCells == viewModel.count
        selectionButton.setTitle(areAllSelected ? .LoginListDeselctAll : .LoginListSelctAll, for: [])
    }

    // MARK: Telemetry
    private func sendLoginsDeletedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .loginsDeleted)
    }

    private func sendLoginsManagementAddTappedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsManagementAddTapped)
    }

    private func sendLoginsManagementLoginsTappedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsManagementLoginsTapped)
    }
}

extension PasswordManagerListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        if tableView.isEditing {
            selectionButton.isHidden = !query.isEmpty
        }
        loadLogins(query)
    }
}

extension PasswordManagerListViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.setIsDuringSearchControllerDismiss(to: true)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        viewModel.setIsDuringSearchControllerDismiss(to: false)
    }
}

// MARK: - Selectors
private extension PasswordManagerListViewController {
    @objc
    func remoteLoginsDidChange() {
        DispatchQueue.main.async {
            self.loadLogins()
        }
    }

    @objc
    func dismissAlertController() {
        self.deleteAlert?.dismiss(animated: false, completion: nil)
        navigationController?.view.endEditing(true)
    }

    func loadLogins(_ query: String? = nil) {
        loadingView.isHidden = false
        loadingView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        viewModel.loadLogins(query, loginDataSource: self.loginDataSource)
    }

    @objc
    func beginEditing() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.leftBarButtonItems = [cancelSelectionButton]
        selectionButton.isHidden = false
        selectionButton.setTitle(.LoginListSelctAll, for: [])
        self.view.layoutIfNeeded()
        tableView.setEditing(true, animated: true)
        tableView.reloadData()
    }

    @objc
    func presentAddCredential() {
        let completion: (LoginEntry) -> Void = { [weak self] record in
            self?.viewModel.save(loginRecord: record) { _ in
                DispatchQueue.main.async {
                    self?.loadLogins()
                    self?.tableView.reloadData()
                }
            }
        }
        sendLoginsManagementAddTappedTelemetry()
        coordinator?.pressedAddPassword(completion: completion)
    }

    @objc
    func cancelSelection() {
        // Update selection and select all button
        viewModel.listSelectionHelper.removeAllCells()
        toggleSelectionTitle()
        selectionButton.isHidden = true
        self.view.layoutIfNeeded()

        tableView.setEditing(false, animated: true)
        setupDefaultNavButtons()
        tableView.reloadData()
    }

    @objc
    func tappedDelete() {
        viewModel.profile.hasSyncedLogins().uponQueue(.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                // Delete here
                let guidsToDelete = self.tableView.allLoginIndexPaths.compactMap { index in
                    if let loginRecord = self.viewModel.loginAtIndexPath(index),
                       self.viewModel.listSelectionHelper.isCellSelected(with: loginRecord) {
                        return loginRecord.id
                    }
                    return nil
                }

                self.viewModel.profile.logins.deleteLogins(ids: guidsToDelete) { _ in
                    DispatchQueue.main.async {
                        self.cancelSelection()
                        self.loadLogins()
                        self.sendLoginsDeletedTelemetry()
                    }
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    @objc
    func tappedSelectionButton() {
        // If we haven't selected everything yet, select all
        if viewModel.listSelectionHelper.numberOfSelectedCells < viewModel.count {
            tableView.allLoginIndexPaths.forEach {
                tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
            }
            viewModel.loginRecordSections.forEach {
                $1.forEach { viewModel.listSelectionHelper.setCellSelected(with: $0) }
            }
        } else {
            tableView.allLoginIndexPaths.forEach {
                tableView.deselectRow(at: $0, animated: false)
            }
            viewModel.listSelectionHelper.removeAllCells()
        }
        toggleSelectionTitle()
        toggleDeleteBarButton()
    }
}

// MARK: - UITableViewDelegate
extension PasswordManagerListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Headers are hidden except for the first login section, which has a title (see also viewForHeaderInSection)
        return section == 1 ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Only the start of the logins list gets a title
        if section != 1 {
            return nil
        }
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }
        headerView.titleLabel.text = .LoginsListTitle
        // not using a grouped table: show header borders
        headerView.showBorder(for: .top, true)
        headerView.showBorder(for: .bottom, true)
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == PasswordManagerListViewController.loginsSettingsSection,
           searchController.isActive || tableView.isEditing {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Prevent row selection for logins settings section
        indexPath.section == PasswordManagerListViewController.loginsSettingsSection ? nil : indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let loginRecord = viewModel.loginAtIndexPath(indexPath) {
                viewModel.listSelectionHelper.setCellSelected(with: loginRecord)
            }
            toggleSelectionTitle()
            toggleDeleteBarButton()
        } else if let login = viewModel.loginAtIndexPath(indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            var breachRecord: BreachRecord?
            if viewModel.breachIndexPath.contains(indexPath) {
                breachRecord = viewModel.breachAlertsManager.breachRecordForLogin(login)
            }
            let detailViewModel = PasswordDetailViewControllerModel(
                profile: viewModel.profile,
                login: login,
                breachRecord: breachRecord
            )
            sendLoginsManagementLoginsTappedTelemetry()
            coordinator?.pressedPasswordDetail(model: detailViewModel)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            if let loginRecord = viewModel.loginAtIndexPath(indexPath) {
                viewModel.listSelectionHelper.removeCell(with: loginRecord)
            }
            toggleSelectionTitle()
            toggleDeleteBarButton()
        }
    }
}

// MARK: - KeyboardHelperDelegate
extension PasswordManagerListViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - LoginViewModelDelegate
extension PasswordManagerListViewController: LoginViewModelDelegate {
    func breachPathDidUpdate() {
        DispatchQueue.main.async {
            self.viewModel.breachIndexPath.forEach {
                guard let cell = self.tableView.cellForRow(at: $0) as? PasswordManagerTableViewCell else { return }
                cell.breachAlertImageView.isHidden = false
                cell.accessibilityValue = "Breached Login Alert"
            }
        }
    }

    func loginSectionsDidUpdate() {
        loadingView.isHidden = true
        tableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.hasData
        toggleSelectionTitle()
    }
}

// MARK: - UITableView extension
private extension UITableView {
    var allLoginIndexPaths: [IndexPath] {
        return (
            (PasswordManagerListViewController.loginsSettingsSection + 1)..<self.numberOfSections
        ).flatMap { sectionNum in
            (0..<self.numberOfRows(inSection: sectionNum)).map {
                IndexPath(row: $0, section: sectionNum)
            }
        }
    }
}
