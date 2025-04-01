// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

class ScreenshotSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "ScreenshotSetting.Setting" }
    private let imageStore: DiskImageStore

    init(settings: SettingsTableViewController,
         imageStore: DiskImageStore = AppContainer.shared.resolve()) {
        self.imageStore = imageStore
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Delete screenshots (needs restart)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Task {
            try? await imageStore.clearAllScreenshotsExcluding([])
            fatalError("Force exit to clear screenshots")
        }
    }
}
