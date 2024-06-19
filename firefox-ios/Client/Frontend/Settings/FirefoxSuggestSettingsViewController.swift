// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

/// A view controller that manages the hidden Firefox Suggest debug settings.
class FirefoxSuggestSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    init(profile: Profile, windowUUID: WindowUUID) {
        super.init(style: .grouped, windowUUID: windowUUID)
        self.profile = profile
        self.title = "Firefox Suggest"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let enabled = BoolSetting(
            with: .firefoxSuggestFeature,
            titleText: NSAttributedString(
                string: "Enable Firefox Suggest",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
        ) { [weak self] _ in
            guard let self else { return }
            self.settings = self.generateSettings()
            self.tableView.reloadData()
        }

        var sections: [SettingSection] = [SettingSection(title: nil, children: [enabled])]
        if featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) {
            sections.append(SettingSection(
                title: nil,
                children: [
                    ForceFirefoxSuggestIngestSetting(profile: profile)
                ]
            ))
        }
        return sections
    }
}

/// A Firefox Suggest debug setting that downloads and stores new suggestions
/// immediately, without waiting for the background ingestion task to run.
class ForceFirefoxSuggestIngestSetting: Setting {
    let profile: Profile
    let logger: Logger

    init(profile: Profile, logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
        super.init()
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Ingest new suggestions now",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_: UINavigationController?) {
        Task { [weak self] in
            guard let self else { return }
            logger.log("Ingesting new suggestions",
                       level: .info,
                       category: .storage)
            do {
                try await self.profile.firefoxSuggest?.ingest()
                logger.log("Successfully ingested new suggestions",
                           level: .info,
                           category: .storage)
            } catch {
                logger.log("Failed to ingest new suggestions: \(error.localizedDescription)",
                           level: .warning,
                           category: .storage)
            }
        }
    }
}
