// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

final class TranslationLanguagePickerViewController: UIViewController,
                                                     UITableViewDataSource,
                                                     UITableViewDelegate,
                                                     UISearchResultsUpdating,
                                                     Themeable {
    // MARK: - Properties

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: WindowUUID? { windowUUID }

    let windowUUID: WindowUUID

    private let allLanguages: [String]
    private var filteredLanguages: [String]

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = .Settings.Translation.LanguagePicker.SearchPlaceholder
        return searchController
    }()

    // MARK: - Init

    init(windowUUID: WindowUUID,
         preferredLanguages: [String],
         supportedLanguages: [String],
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        let preferred = Set(preferredLanguages)
        self.allLanguages = supportedLanguages
            .filter { !preferred.contains($0) }
            .sorted { lhs, rhs in
                let lhsName = Locale(identifier: lhs).localizedString(forLanguageCode: lhs) ?? lhs
                let rhsName = Locale(identifier: rhs).localizedString(forLanguageCode: rhs) ?? rhs
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
        self.filteredLanguages = self.allLanguages
        super.init(nibName: nil, bundle: nil)
        title = .Settings.Translation.LanguagePicker.NavTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        definesPresentationContext = true
        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    // MARK: - Setup

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let code = filteredLanguages[indexPath.row]
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        var content = cell.defaultContentConfiguration()
        let native = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
        let localized = Locale.current.localizedString(forLanguageCode: code) ?? code
        content.text = native
        content.textProperties.color = theme.colors.textPrimary
        content.secondaryText = native == localized ? nil : localized
        content.secondaryTextProperties.color = theme.colors.textSecondary
        cell.contentConfiguration = content
        cell.backgroundColor = theme.colors.layer2

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let languageCode = filteredLanguages[indexPath.row]
        store.dispatch(TranslationSettingsViewAction(
            languageCode: languageCode,
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.addLanguage
        ))
        dismiss(animated: true)
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        if query.isEmpty {
            filteredLanguages = allLanguages
        } else {
            filteredLanguages = allLanguages.filter { code in
                let native = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
                let localized = Locale.current.localizedString(forLanguageCode: code) ?? code
                return native.localizedCaseInsensitiveContains(query)
                    || localized.localizedCaseInsensitiveContains(query)
            }
        }
        tableView.reloadData()
    }

    // MARK: - Theming

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        tableView.reloadData()
    }
}
