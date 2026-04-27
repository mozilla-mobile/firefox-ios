// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TranslationLanguagePickerResultsController: UITableViewController, Themeable {
    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: WindowUUID? { windowUUID }

    // MARK: - Properties

    let windowUUID: WindowUUID
    private let localeProvider: LocaleProvider
    private let onSelectLanguage: (String) -> Void
    private(set) var filteredLanguages: [String] = []

    // MARK: - Init

    init(windowUUID: WindowUUID,
         localeProvider: LocaleProvider,
         themeManager: ThemeManager,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         onSelectLanguage: @escaping (String) -> Void) {
        self.windowUUID = windowUUID
        self.localeProvider = localeProvider
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.onSelectLanguage = onSelectLanguage
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TranslationPickerLanguageCell.self,
                           forCellReuseIdentifier: TranslationPickerLanguageCell.cellIdentifier)
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Translation.languagePickerList
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    // MARK: - Configuration

    func configure(filteredLanguages: [String]) {
        self.filteredLanguages = filteredLanguages
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectLanguage(filteredLanguages[indexPath.row])
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tableView.backgroundColor = theme.colors.layer1
        tableView.visibleCells.compactMap { $0 as? TranslationPickerLanguageCell }.forEach {
            $0.applyTheme(theme: theme)
        }
    }
}
