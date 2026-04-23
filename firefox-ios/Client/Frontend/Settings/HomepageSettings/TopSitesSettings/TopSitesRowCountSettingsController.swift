// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class TopSitesRowCountSettingsController: SettingsTableViewController, FeatureFlaggable {
    let prefs: Prefs
    var numberOfRows: Int32
    nonisolated static let defaultNumberOfRows: Int32 = 2

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        numberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        super.init(style: .grouped, windowUUID: windowUUID)

        self.title = .Settings.Homepage.Shortcuts.RowsPageTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        updateNumberofRows()
        let createSetting: (Int32) -> CheckmarkSetting = { num in
            return CheckmarkSetting(title: NSAttributedString(string: "\(num)"),
                                    subtitle: nil,
                                    isChecked: {
                return num == self.numberOfRows
            },
                                    onChecked: {
                guard self.numberOfRows != num else { return }
                self.numberOfRows = num
                self.prefs.setInt(Int32(num), forKey: PrefsKeys.NumberOfTopSiteRows)
                self.tableView.reloadData()

                store.dispatch(
                    TopSitesAction(
                        numberOfRows: Int(num),
                        windowUUID: self.windowUUID,
                        actionType: TopSitesActionType.updatedNumberOfRows
                    )
                )
            })
        }

        var rows = [CheckmarkSetting]()
        if featureFlagsProvider.isEnabled(.homepageSearchBar) {
            rows = [1, 2].map(createSetting)
        } else {
            rows = [1, 2, 3, 4].map(createSetting)
        }

        return [SettingSection(
            title: NSAttributedString(string: .Settings.Homepage.Shortcuts.RowSettingFooter),
            footerTitle: nil,
            children: rows
        )]
    }

    private func updateNumberofRows() {
        let defaultValue = TopSitesRowCountSettingsController.defaultNumberOfRows
        if featureFlagsProvider.isEnabled(.homepageSearchBar) {
            let savedNumberOfRows = self.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? defaultValue
            numberOfRows = savedNumberOfRows > 2 ? defaultValue : savedNumberOfRows
        } else {
            numberOfRows = self.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? defaultValue
        }
    }
}
