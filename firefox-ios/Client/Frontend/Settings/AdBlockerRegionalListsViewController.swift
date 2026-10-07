// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Displays available regional ad-block lists as toggle rows.
/// Each list can be independently enabled or disabled.
final class AdBlockerRegionalListsViewController: UIViewController,
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

    private let prefs: Prefs
    private let fetcher: AdBlockerListFetcherProtocol
    private var availableListIDs: [String] = []
    private var enabledListIDs: Set<String> = []
    private var isLoading = true

    private struct UX {
        static let cellHeight: CGFloat = 51
        static let emptyStatePadding: CGFloat = 32
    }

    // MARK: - Subviews

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        table.register(cellType: ThemedTableViewCell.self)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = .Settings.Browsing.RegionalLists.EmptyStateDescription
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Browsing.AdBlockerRegionalLists.emptyState
        return label
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Init

    init(windowUUID: WindowUUID,
         prefs: Prefs,
         fetcher: AdBlockerListFetcherProtocol = ContentBlocker.shared.adBlockerListFetcher,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.prefs = prefs
        self.fetcher = fetcher
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
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        loadEnabledLists()
        fetchAvailableLists()
    }

    // MARK: - Setup

    private func setupView() {
        title = .Settings.Browsing.RegionalLists.Title

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.emptyStatePadding),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.emptyStatePadding),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Data

    private func loadEnabledLists() {
        let stored = prefs.stringArrayForKey(PrefsKeys.EnabledRegionalAdBlockLists) ?? []
        enabledListIDs = Set(stored)
    }

    private func saveEnabledLists() {
        prefs.setObject(Array(enabledListIDs).sorted(), forKey: PrefsKeys.EnabledRegionalAdBlockLists)
    }

    private func fetchAvailableLists() {
        isLoading = true
        activityIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateLabel.isHidden = true

        Task {
            let ids = await fetcher.fetchAvailableRegionalListIDs()
            availableListIDs = ids
            isLoading = false
            activityIndicator.stopAnimating()
            updateUIForCurrentState()
            tableView.reloadData()
        }
    }

    private func updateUIForCurrentState() {
        let isEmpty = availableListIDs.isEmpty && !isLoading
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty || isLoading
    }

    /// Extracts the region code from a record ID (e.g. "ad-block-regional-de" → "de").
    private func regionCode(for recordID: String) -> String {
        return String(recordID.dropFirst(ASAdBlockerListFetcher.regionalRecordPrefix.count))
    }

    /// Returns a user-facing display name for a regional list record ID.
    func displayName(for recordID: String) -> String {
        let code = regionCode(for: recordID)
        return Locale.current.localizedString(forLanguageCode: code)?.localizedCapitalized ?? code.uppercased()
    }

    // MARK: - Toggle

    @objc
    private func toggleChanged(_ sender: UISwitch) {
        let recordID = availableListIDs[sender.tag]

        if sender.isOn {
            enabledListIDs.insert(recordID)
            saveEnabledLists()
            Task {
                await ContentBlocker.shared.reloadRegionalLists(enabledIDs: [recordID])
                ContentBlocker.shared.prefsChanged()
            }
        } else {
            enabledListIDs.remove(recordID)
            saveEnabledLists()
            Task {
                await ContentBlocker.shared.removeRegionalList(identifier: recordID)
                ContentBlocker.shared.prefsChanged()
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableListIDs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedTableViewCell.cellIdentifier,
            for: indexPath
        ) as? ThemedTableViewCell else {
            return UITableViewCell()
        }

        let recordID = availableListIDs[indexPath.row]
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        cell.textLabel?.text = displayName(for: recordID)
        cell.textLabel?.textColor = theme.colors.textPrimary
        cell.selectionStyle = .none
        cell.applyTheme(theme: theme)

        let toggle = UISwitch()
        toggle.isOn = enabledListIDs.contains(recordID)
        toggle.onTintColor = theme.colors.actionPrimary
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard !availableListIDs.isEmpty else { return nil }
        return .Settings.Browsing.RegionalLists.FooterDescription
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UX.cellHeight
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
        tableView.separatorColor = theme.colors.borderPrimary
        emptyStateLabel.textColor = theme.colors.textSecondary
        emptyStateLabel.font = FXFontStyles.Regular.body.scaledFont()
    }
}
