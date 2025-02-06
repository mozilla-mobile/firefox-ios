// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

final class AddOneSeedSetting: HiddenSetting {

    // This property holds a reference to the type conforming to SeedProgressManagerProtocol
    private let progressManagerType: SeedProgressManagerProtocol.Type

    // MARK: - Init
    init(settings: SettingsTableViewController,
         progressManagerType: SeedProgressManagerProtocol.Type) {
        self.progressManagerType = progressManagerType
        super.init(settings: settings)
    }

    // MARK: - Title
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: Add One Seed",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Status
    override var status: NSAttributedString? {
        let seedsCollected = progressManagerType.loadTotalSeedsCollected()
        let level = progressManagerType.loadCurrentLevel()
        return NSAttributedString(
            string: "Seeds: \(seedsCollected) | Level: \(level)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Action
    override func onClick(_ navigationController: UINavigationController?) {
        // Add 1 seed to the counter using the static method of the passed progressManager type
        progressManagerType.addSeeds(1, relativeToDate: progressManagerType.loadLastAppOpenDate())
        settings.tableView.reloadData()
    }
}

final class AddFiveSeedsSetting: HiddenSetting {

    // This property holds a reference to the type conforming to SeedProgressManagerProtocol
    private let progressManagerType: SeedProgressManagerProtocol.Type

    // MARK: - Init
    init(settings: SettingsTableViewController,
         progressManagerType: SeedProgressManagerProtocol.Type) {
        self.progressManagerType = progressManagerType
        super.init(settings: settings)
    }

    // MARK: - Title
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: Add Five Seeds",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Status
    override var status: NSAttributedString? {
        let seedsCollected = progressManagerType.loadTotalSeedsCollected()
        let level = progressManagerType.loadCurrentLevel()
        return NSAttributedString(
            string: "Seeds: \(seedsCollected) | Level: \(level)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Action
    override func onClick(_ navigationController: UINavigationController?) {
        // Add 5 seeds to the counter using the static method of the passed progressManager type
        progressManagerType.addSeeds(5, relativeToDate: progressManagerType.loadLastAppOpenDate())
        settings.tableView.reloadData()
    }
}

final class ResetSeedCounterSetting: HiddenSetting {

    // This property holds a reference to the type conforming to SeedProgressManagerProtocol
    private let progressManagerType: SeedProgressManagerProtocol.Type

    // MARK: - Init
    init(settings: SettingsTableViewController,
         progressManagerType: SeedProgressManagerProtocol.Type) {
        self.progressManagerType = progressManagerType
        super.init(settings: settings)
    }

    // MARK: - Title
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: Reset Seed Counter",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Status
    override var status: NSAttributedString? {
        let seedsCollected = progressManagerType.loadTotalSeedsCollected()
        let level = progressManagerType.loadCurrentLevel()
        return NSAttributedString(
            string: "Seeds: \(seedsCollected) | Level: \(level)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.ecosia.tableViewRowText]
        )
    }

    // MARK: - Action
    override func onClick(_ navigationController: UINavigationController?) {
        // Reset the seed counter using the static method of the passed progressManager type
        progressManagerType.resetCounter()
        settings.tableView.reloadData()
    }
}

final class UnleashSeedCounterNTPSetting: UnleashVariantResetSetting {
    // MARK: - Title
    override var titleName: String? {
        "Seed Counter NTP"
    }

    override var variant: Unleash.Variant? {
        Unleash.getVariant(.seedCounterNTP)
    }
}
