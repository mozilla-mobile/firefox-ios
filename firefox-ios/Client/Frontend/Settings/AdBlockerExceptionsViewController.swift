// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SiteImageView
import Shared
import UIKit

protocol AdBlockerExceptionsDelegate: AnyObject {
    func adBlockerExceptionsDidChange()
}

final class AdBlockerExceptionsViewController: UIViewController,
                                               UITableViewDataSource,
                                               UITableViewDelegate,
                                               Themeable {
    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: - Properties

    weak var delegate: AdBlockerExceptionsDelegate?
    private let exceptionsStorage: AdBlockerExceptionsStorageProtocol
    private var isInEditMode = false
    private var selectedDomains = Set<String>()

    private struct UX {
        static let faviconSize: CGFloat = 24
        static let cellHeight: CGFloat = 51
        static let emptyStatePadding: CGFloat = 32
        static let footerPadding: CGFloat = 16
        static let toolbarHeight: CGFloat = 44
    }

    // MARK: - Subviews

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.allowsMultipleSelectionDuringEditing = true
        table.register(cellType: ThemedTableViewCell.self)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = .Settings.Browsing.Exceptions.EmptyStateDescription
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.emptyState
        return label
    }()

    private lazy var editButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: .Settings.Browsing.Exceptions.EditButton,
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
    }()

    private lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.addButton
        return button
    }()

    private lazy var deleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: .Settings.Browsing.Exceptions.DeleteConfirmationButton,
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.deleteButton
        return button
    }()

    private lazy var selectAllButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: .Settings.Browsing.Exceptions.SelectAllButton,
            style: .plain,
            target: self,
            action: #selector(selectAllButtonTapped)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.selectAllButton
        return button
    }()

    // MARK: - Init

    init(windowUUID: WindowUUID,
         exceptionsStorage: AdBlockerExceptionsStorageProtocol = AdBlockerExceptionsStorage.shared,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.exceptionsStorage = exceptionsStorage
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupToolbar()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        updateUIForCurrentState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        title = .Settings.Browsing.Exceptions.Title

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.emptyStatePadding),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.emptyStatePadding)
        ])
    }

    private func setupNavigationBar() {
        editButton.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerExceptions.editButton
        navigationItem.rightBarButtonItem = editButton
    }

    private func setupToolbar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexibleSpace, addButton]
    }

    // MARK: - State Management

    private func updateUIForCurrentState() {
        let isEmpty = exceptionsStorage.domains.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        editButton.isEnabled = !isEmpty

        if isInEditMode {
            updateEditModeToolbar()
            updateDeleteButtonState()
        } else {
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [flexibleSpace, addButton]
        }
    }

    private func updateEditModeToolbar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let allSelected = selectedDomains.count == exceptionsStorage.count
        selectAllButton.title = allSelected
            ? String.Settings.Browsing.Exceptions.DeselectAllButton
            : String.Settings.Browsing.Exceptions.SelectAllButton
        toolbarItems = [deleteButton, flexibleSpace, selectAllButton]
    }

    private func updateDeleteButtonState() {
        deleteButton.isEnabled = !selectedDomains.isEmpty
    }

    private func enterEditMode() {
        isInEditMode = true
        selectedDomains.removeAll()
        tableView.setEditing(true, animated: true)
        editButton.title = .Settings.Browsing.Exceptions.DoneButton
        editButton.style = .done
        updateUIForCurrentState()
    }

    private func exitEditMode() {
        isInEditMode = false
        selectedDomains.removeAll()
        tableView.setEditing(false, animated: true)
        editButton.title = .Settings.Browsing.Exceptions.EditButton
        editButton.style = .plain
        updateUIForCurrentState()
    }

    // MARK: - Actions

    @objc
    private func editButtonTapped() {
        if isInEditMode {
            exitEditMode()
        } else {
            enterEditMode()
        }
    }

    @objc
    private func addButtonTapped() {
        presentAddExceptionAlert()
    }

    @objc
    private func deleteButtonTapped() {
        guard !selectedDomains.isEmpty else { return }

        if selectedDomains.count > 1 {
            presentDeleteConfirmation()
        } else {
            deleteSelectedDomains()
        }
    }

    @objc
    private func selectAllButtonTapped() {
        let allSelected = selectedDomains.count == exceptionsStorage.count
        if allSelected {
            selectedDomains.removeAll()
            for row in 0..<exceptionsStorage.count {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
            }
        } else {
            selectedDomains = Set(exceptionsStorage.domains)
            for row in 0..<exceptionsStorage.count {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
            }
        }
        updateEditModeToolbar()
        updateDeleteButtonState()
    }

    // MARK: - Alerts

    private func presentAddExceptionAlert() {
        let alert = UIAlertController(
            title: .Settings.Browsing.Exceptions.AddAlertTitle,
            message: .Settings.Browsing.Exceptions.AddAlertMessage,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = String.Settings.Browsing.Exceptions.AddAlertPlaceholder
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        let saveAction = UIAlertAction(
            title: .Settings.Browsing.Exceptions.AddAlertSave,
            style: .default
        ) { [weak self] _ in
            guard let domain = alert.textFields?.first?.text, !domain.isEmpty else { return }
            self?.addException(domain: domain)
        }
        saveAction.isEnabled = false

        let cancelAction = UIAlertAction(
            title: .Settings.Browsing.Exceptions.AddAlertCancel,
            style: .cancel
        )

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        alert.preferredAction = saveAction

        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alert.textFields?.first,
            queue: .main
        ) { notification in
            guard let textField = notification.object as? UITextField else { return }
            saveAction.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }

        present(alert, animated: true) {
            alert.textFields?.first?.becomeFirstResponder()
        }
    }

    private func presentDeleteConfirmation() {
        let alert = UIAlertController(
            title: .Settings.Browsing.Exceptions.DeleteConfirmationTitle,
            message: nil,
            preferredStyle: .actionSheet
        )

        let deleteAction = UIAlertAction(
            title: .Settings.Browsing.Exceptions.DeleteConfirmationButton,
            style: .destructive
        ) { [weak self] _ in
            self?.deleteSelectedDomains()
        }

        let cancelAction = UIAlertAction(
            title: .Settings.Browsing.Exceptions.AddAlertCancel,
            style: .cancel
        )

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = deleteButton
        }

        present(alert, animated: true)
    }

    // MARK: - Domain Management

    private func addException(domain: String) {
        exceptionsStorage.addDomain(domain)
        tableView.reloadData()
        updateUIForCurrentState()
        notifyExceptionsChanged()
    }

    private func deleteSelectedDomains() {
        exceptionsStorage.removeDomains(selectedDomains)
        selectedDomains.removeAll()
        tableView.reloadData()
        exitEditMode()
        notifyExceptionsChanged()
    }

    private func notifyExceptionsChanged() {
        delegate?.adBlockerExceptionsDidChange()
        Task {
            await ContentBlocker.shared.reloadAdBlockerList()
            ContentBlocker.shared.prefsChanged()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exceptionsStorage.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedTableViewCell.cellIdentifier,
            for: indexPath
        ) as? ThemedTableViewCell else {
            return UITableViewCell()
        }

        let domain = exceptionsStorage.domains[indexPath.row]
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        cell.textLabel?.text = domain
        cell.textLabel?.textColor = theme.colors.textPrimary
        cell.backgroundColor = theme.colors.layer5

        let faviconFrame = CGRect(x: 0, y: 0, width: UX.faviconSize, height: UX.faviconSize)
        let favicon = FaviconImageView(frame: faviconFrame)
        favicon.setFavicon(FaviconImageViewModel(siteURLString: "https://\(domain)"))
        cell.imageView?.image = UIImage()
        cell.imageView?.addSubview(favicon)
        favicon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            favicon.centerXAnchor.constraint(equalTo: cell.imageView!.centerXAnchor),
            favicon.centerYAnchor.constraint(equalTo: cell.imageView!.centerYAnchor)
        ])

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !exceptionsStorage.domains.isEmpty else { return nil }
        return .Settings.Browsing.Exceptions.FooterDescription
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UX.cellHeight
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let domain = exceptionsStorage.domains[indexPath.row]
            exceptionsStorage.removeDomain(domain)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateUIForCurrentState()
            notifyExceptionsChanged()
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isInEditMode else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        selectedDomains.insert(exceptionsStorage.domains[indexPath.row])
        updateEditModeToolbar()
        updateDeleteButtonState()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isInEditMode else { return }
        selectedDomains.remove(exceptionsStorage.domains[indexPath.row])
        updateEditModeToolbar()
        updateDeleteButtonState()
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        if isInEditMode {
            return .init(rawValue: 3) ?? .delete // Multi-select style
        }
        return .delete
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
        tableView.separatorColor = theme.colors.borderPrimary
        emptyStateLabel.textColor = theme.colors.textSecondary
        emptyStateLabel.font = FXFontStyles.Regular.body.scaledFont()
        navigationController?.toolbar.barTintColor = theme.colors.layer1
        navigationController?.toolbar.tintColor = theme.colors.actionPrimary
        deleteButton.tintColor = theme.colors.textCritical
    }
}
