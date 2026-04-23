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
    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: WindowUUID? { windowUUID }

    // MARK: - Properties

    let windowUUID: WindowUUID
    private let localeProvider: LocaleProvider
    private let allLanguages: [String]
    private var filteredLanguages: [String]

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TranslationPickerLanguageCell.self,
                           forCellReuseIdentifier: TranslationPickerLanguageCell.cellIdentifier)
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Translation.languagePickerList
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
         languages: [String],
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.localeProvider = localeProvider
        self.allLanguages = languages
        self.filteredLanguages = languages
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
        applyTheme()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TranslationPickerLanguageCell.cellIdentifier,
            for: indexPath
        ) as? TranslationPickerLanguageCell ?? TranslationPickerLanguageCell()
        let code = filteredLanguages[indexPath.row]
        let native = localeProvider.nativeLanguageName(for: code)
        let localized = localeProvider.localizedLanguageName(for: code)
        cell.configure(native: native, localized: native == localized ? nil : localized)
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
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
        let newFiltered = query.isEmpty ? allLanguages : allLanguages.filter { code in
            let native = localeProvider.nativeLanguageName(for: code)
            let localized = localeProvider.localizedLanguageName(for: code)
            return native.localizedCaseInsensitiveContains(query)
                || localized.localizedCaseInsensitiveContains(query)
        }
        guard newFiltered != filteredLanguages else { return }
        filteredLanguages = newFiltered
        tableView.reloadData()
    }

    // MARK: - Theming

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
        searchController.searchBar.tintColor = theme.colors.actionPrimary
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        tableView.visibleCells.compactMap { $0 as? TranslationPickerLanguageCell }.forEach {
            $0.applyTheme(theme: theme)
        }
    }
}
