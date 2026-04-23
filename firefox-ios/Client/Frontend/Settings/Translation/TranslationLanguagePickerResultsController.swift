// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class TranslationLanguagePickerResultsController: UITableViewController {
    var filteredLanguages: [String] = []
    var onSelectLanguage: ((String) -> Void)?
    var localeProvider: LocaleProvider = SystemLocaleProvider()
    var theme: Theme?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TranslationPickerLanguageCell.self,
                           forCellReuseIdentifier: TranslationPickerLanguageCell.cellIdentifier)
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Translation.languagePickerList
    }

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
        if let theme { cell.applyTheme(theme: theme) }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectLanguage?(filteredLanguages[indexPath.row])
    }
}
