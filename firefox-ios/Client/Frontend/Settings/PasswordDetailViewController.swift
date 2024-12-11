// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import Common

import struct MozillaAppServices.LoginEntry

class PasswordDetailViewController: SensitiveViewController, Themeable {
    private struct UX {
        static let horizontalMargin: CGFloat = 14
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private lazy var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.accessibilityIdentifier = "Login Detail List"
        tableView.delegate = self
        tableView.dataSource = self

        // Add empty footer view to prevent separators from being drawn past the last item.
        tableView.tableFooterView = UIView()
    }

    private weak var websiteField: UITextField?
    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    private var deleteAlert: UIAlertController?
    weak var settingsDelegate: SettingsDelegate?
    weak var coordinator: PasswordManagerFlowDelegate?

    private var viewModel: PasswordDetailViewControllerModel

    private var isEditingFieldData = false {
        didSet {
            if isEditingFieldData != oldValue {
                tableView.reloadData()
            }
        }
    }

    init(viewModel: PasswordDetailViewControllerModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismissAlertController),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit,
                                                            target: self,
                                                            action: #selector(edit))

        tableView.register(cellType: LoginDetailTableViewCell.self)
        tableView.register(cellType: LoginDetailCenteredTableViewCell.self)
        tableView.register(cellType: ThemedTableViewCell.self)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.estimatedRowHeight = 44.0
        tableView.separatorInset = .zero

        applyTheme()
        listenForThemeChange(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Normally UITableViewControllers handle responding to content inset changes from keyboard events when
        // editing but since we don't use the tableView's editing flag for editing we handle this ourselves.
        KeyboardHelper.defaultHelper.addDelegate(self)
    }

    private func didTapBreachLearnMore() {
        guard let url = BreachAlertsManager.monitorAboutUrl else { return }
        coordinator?.openURL(url: url)
    }

    private func didTapBreachLink(_ sender: UITapGestureRecognizer? = nil) {
        guard let domain = viewModel.breachRecord?.domain else { return }
        var urlComponents = URLComponents()
        urlComponents.host = domain
        urlComponents.scheme = "https"
        guard let url = urlComponents.url else { return }
        coordinator?.openURL(url: url)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        tableView.separatorColor = theme.colors.borderPrimary
        tableView.backgroundColor = theme.colors.layer1
    }
}

// MARK: - UITableViewDataSource
extension PasswordDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = viewModel.cellType(atIndexPath: indexPath) else { return UITableViewCell() }

        switch cellType {
        case .breach:
            guard let breachCell = cell(tableView: tableView, forIndexPath: indexPath) else {
                return UITableViewCell()
            }
            guard let breach = viewModel.breachRecord else { return breachCell }
            breachCell.isHidden = false
            let breachDetailView: BreachAlertsDetailView = .build()
            breachCell.contentView.addSubview(breachDetailView)

            NSLayoutConstraint.activate([
                breachDetailView.leadingAnchor.constraint(equalTo: breachCell.contentView.leadingAnchor,
                                                          constant: UX.horizontalMargin),
                breachDetailView.topAnchor.constraint(equalTo: breachCell.contentView.topAnchor,
                                                      constant: UX.horizontalMargin),
                breachDetailView.trailingAnchor.constraint(equalTo: breachCell.contentView.trailingAnchor,
                                                           constant: -UX.horizontalMargin),
                breachDetailView.bottomAnchor.constraint(equalTo: breachCell.contentView.bottomAnchor,
                                                         constant: -UX.horizontalMargin)
            ])
            breachDetailView.setup(breach)
            breachDetailView.applyTheme(theme: currentTheme())

            breachDetailView.onTapLearnMore = { [weak self] in
                self?.didTapBreachLearnMore()
            }

            breachDetailView.onTapBreachLink = { [weak self] in
                self?.didTapBreachLink()
            }

            breachCell.isAccessibilityElement = false
            breachCell.contentView.accessibilityElementsHidden = true
            breachCell.accessibilityElements = [breachDetailView]
            breachCell.applyTheme(theme: currentTheme())

            return breachCell

        case .username:
            guard let loginCell = cell(tableView: tableView, forIndexPath: indexPath) else {
                return UITableViewCell()
            }
            let cellModel = LoginDetailTableViewCellModel(
                title: .LoginDetailUsername,
                description: viewModel.login.decryptedUsername,
                keyboardType: .emailAddress,
                returnKeyType: .next,
                a11yId: AccessibilityIdentifiers.Settings.Passwords.usernameField,
                isEditingFieldData: isEditingFieldData)
            loginCell.configure(viewModel: cellModel)
            loginCell.applyTheme(theme: currentTheme())
            usernameField = loginCell.descriptionLabel
            return loginCell

        case .password:
            guard let loginCell = cell(tableView: tableView, forIndexPath: indexPath) else {
                return UITableViewCell()
            }
            let cellModel = LoginDetailTableViewCellModel(
                title: .LoginDetailPassword,
                description: viewModel.login.decryptedPassword,
                displayDescriptionAsPassword: true,
                a11yId: AccessibilityIdentifiers.Settings.Passwords.passwordField,
                isEditingFieldData: isEditingFieldData)
            setCellSeparatorHidden(loginCell)
            loginCell.configure(viewModel: cellModel)
            loginCell.applyTheme(theme: currentTheme())
            passwordField = loginCell.descriptionLabel
            return loginCell

        case .website:
            guard let loginCell = cell(tableView: tableView, forIndexPath: indexPath) else {
                return UITableViewCell()
            }
            let cellModel = LoginDetailTableViewCellModel(
                title: .LoginDetailWebsite,
                description: viewModel.login.hostname,
                a11yId: AccessibilityIdentifiers.Settings.Passwords.websiteField)
            if isEditingFieldData {
                loginCell.contentView.alpha = 0.5
            }
            loginCell.configure(viewModel: cellModel)
            loginCell.applyTheme(theme: currentTheme())
            websiteField = loginCell.descriptionLabel
            return loginCell

        case .lastModifiedSeparator:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: LoginDetailCenteredTableViewCell.cellIdentifier,
                for: indexPath) as? LoginDetailCenteredTableViewCell else {
                return UITableViewCell()
            }

            let created: String = .LoginDetailCreatedAt
            let lastModified: String = .LoginDetailModifiedAt
            let lastModifiedFormatted = String(
                format: lastModified,
                Date.fromTimestamp(UInt64(viewModel.login.timePasswordChanged))
                    .toRelativeTimeString(dateStyle: .medium)
            )
            let createdFormatted = String(
                format: created,
                Date.fromTimestamp(UInt64(viewModel.login.timeCreated))
                    .toRelativeTimeString(dateStyle: .medium, timeStyle: .none)
            )
            let cellModel = LoginDetailCenteredTableViewCellModel(
                label: createdFormatted + "\n" + lastModifiedFormatted)
            cell.configure(viewModel: cellModel)
            setCellSeparatorHidden(cell)
            cell.applyTheme(theme: currentTheme())
            return cell

        case .delete:
            guard let deleteCell = tableView.dequeueReusableCell(withIdentifier: ThemedTableViewCell.cellIdentifier,
                                                                 for: indexPath) as? ThemedTableViewCell else {
                return UITableViewCell()
            }
            deleteCell.textLabel?.text = .LoginDetailDelete
            deleteCell.textLabel?.textAlignment = .center
            deleteCell.accessibilityTraits = UIAccessibilityTraits.button
            deleteCell.selectionStyle = .none
            deleteCell.configure(viewModel: ThemedTableViewCellViewModel(theme: currentTheme(),
                                                                         type: .destructive))
            deleteCell.applyTheme(theme: currentTheme())

            setCellSeparatorFullWidth(deleteCell)
            return deleteCell
        }
    }

    private func cell(tableView: UITableView, forIndexPath indexPath: IndexPath) -> LoginDetailTableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LoginDetailTableViewCell.cellIdentifier,
                                                       for: indexPath) as? LoginDetailTableViewCell else {
            return nil
        }
        cell.selectionStyle = .none
        cell.delegate = self
        return cell
    }

    private func setCellSeparatorHidden(_ cell: UITableViewCell) {
        // Prevent separator from showing by pushing it off screen by the width of the cell
        cell.separatorInset = UIEdgeInsets(top: 0,
                                           left: 0,
                                           bottom: 0,
                                           right: view.frame.width)
    }

    private func setCellSeparatorFullWidth(_ cell: UITableViewCell) {
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
}

// MARK: - UITableViewDelegate
extension PasswordDetailViewController: UITableViewDelegate {
    private func showMenuOnSingleTap(forIndexPath indexPath: IndexPath) {
        guard let cellType = viewModel.cellType(atIndexPath: indexPath),
            cellType.shouldShowMenu,
            let cell = tableView.cellForRow(at: indexPath) as? LoginDetailTableViewCell
        else { return }

        cell.becomeFirstResponder()

        let menu = UIMenuController.shared
        menu.showMenu(from: tableView, rect: cell.frame)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == viewModel.indexPath(for: LoginDetailCellType.delete) {
            deleteLogin()
        } else if !isEditingFieldData {
            showMenuOnSingleTap(forIndexPath: indexPath)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard viewModel.cellType(atIndexPath: indexPath) != nil else { return UITableView.automaticDimension }
        return UITableView.automaticDimension
    }
}

// MARK: - KeyboardHelperDelegate
extension PasswordDetailViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - Selectors
extension PasswordDetailViewController {
    @objc
    func dismissAlertController() {
        deleteAlert?.dismiss(animated: false, completion: nil)
    }

    func deleteLogin() {
        viewModel.profile.hasSyncedLogins().uponQueue(.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                self.sendLoginsDeletedTelemetry()
                self.viewModel.profile.logins.deleteLogin(id: self.viewModel.login.id) { _ in
                    DispatchQueue.main.async {
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    func onProfileDidFinishSyncing(completion: @escaping () -> Void) {
        // Reload details after syncing.
        viewModel.profile.logins.getLogin(id: viewModel.login.id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let successValue):
                    if let syncedLogin = successValue {
                        self?.viewModel.login = syncedLogin
                    }
                case .failure:
                    break
                }
                completion()
            }
        }
    }

    @objc
    func edit() {
        isEditingFieldData = true
        guard let indexPath = viewModel.indexPath(for: LoginDetailCellType.username),
                let cell = tableView.cellForRow(at: indexPath) as? LoginDetailTableViewCell else { return }
        cell.descriptionLabel.becomeFirstResponder()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneEditing)
        )
    }

    @objc
    func doneEditing() {
        isEditingFieldData = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(edit)
        )

        // Only update if user made changes
        guard let username = usernameField?.text, let password = passwordField?.text else {
            self.tableView.reloadData()
            return
        }

        guard username != viewModel.login.decryptedUsername || password != viewModel.login.decryptedPassword else {
            self.tableView.reloadData()
            return
        }

        let updatedLogin = LoginEntry(
            fromLoginEntryFlattened: LoginEntryFlattened(
                id: viewModel.login.id,
                hostname: viewModel.login.hostname,
                password: password,
                username: username,
                httpRealm: viewModel.login.httpRealm,
                formSubmitUrl: viewModel.login.formSubmitUrl,
                usernameField: viewModel.login.usernameField,
                passwordField: viewModel.login.passwordField
            )
        )

        if updatedLogin.isValid.isSuccess {
            viewModel.profile.logins.updateLogin(id: viewModel.login.id, login: updatedLogin) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.onProfileDidFinishSyncing {
                        // Required to get UI to reload with changed state
                        self.tableView.reloadData()
                    }
                    self.sendLoginsModifiedTelemetry()
                }
            }
        }
    }
}

// MARK: - Cell Delegate
extension PasswordDetailViewController: LoginDetailTableViewCellDelegate {
    func textFieldDidEndEditing(_ cell: LoginDetailTableViewCell) { }
    func textFieldDidChange(_ cell: LoginDetailTableViewCell) { }

    func canPerform(action: Selector, for cell: LoginDetailTableViewCell) -> Bool {
        guard let item = infoItemForCell(cell) else { return false }

        switch item {
        case .website:
            // Menu actions for Website
            return action == MenuHelperLoginModel.selectorCopy || action == MenuHelperLoginModel.selectorOpenAndFill
        case .username:
            // Menu actions for Username
            return action == MenuHelperLoginModel.selectorCopy
        case .password:
            // Menu actions for password
            let revealOption = action == MenuHelperLoginModel.selectorReveal
            let hideOption = action == MenuHelperLoginModel.selectorHide
            let showRevealOption = cell.descriptionLabel.isSecureTextEntry ? revealOption : hideOption
            return action == MenuHelperLoginModel.selectorCopy || showRevealOption
        default:
            return false
        }
    }

    private func cellForItem(_ cellType: LoginDetailCellType) -> LoginDetailTableViewCell? {
        guard let indexPath = viewModel.indexPath(for: cellType) else { return nil }
        return tableView.cellForRow(at: indexPath) as? LoginDetailTableViewCell
    }

    func didSelectOpenAndFillForCell(_ cell: LoginDetailTableViewCell) {
        guard let url = (viewModel.login.formSubmitUrl?.asURL ?? viewModel.login.hostname.asURL) else { return }

        coordinator?.openURL(url: url)
        sendLoginsAutofilledTelemetry()
    }

    func shouldReturnAfterEditingDescription(_ cell: LoginDetailTableViewCell) -> Bool {
        let usernameCell = cellForItem(.username)
        let passwordCell = cellForItem(.password)

        if cell == usernameCell {
            passwordCell?.descriptionLabel.becomeFirstResponder()
        }

        return false
    }

    func infoItemForCell(_ cell: LoginDetailTableViewCell) -> LoginDetailCellType? {
        if let indexPath = tableView.indexPath(for: cell),
           let item = viewModel.cellType(atIndexPath: indexPath) {
            return item
        }
        return nil
    }

    // MARK: Telemetry
    private func sendLoginsDeletedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .loginsDeleted)
    }

    private func sendLoginsModifiedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .loginsModified)
    }

    private func sendLoginsAutofilledTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsAutofilled)
    }
}
