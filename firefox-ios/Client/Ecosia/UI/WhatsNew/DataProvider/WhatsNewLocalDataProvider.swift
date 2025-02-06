// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Ecosia

/// A local data provider for fetching What's New items based on app version updates.
final class WhatsNewLocalDataProvider: WhatsNewDataProvider {

    /// The version from which the app was last updated.
    private var fromVersion: Version? {
        Version(EcosiaInstallType.persistedCurrentVersion())
    }

    /// The current version of the app.
    private var toVersion: Version {
        Version(versionProvider.version)!
    }

    /// A computed property to determine whether the "What's New" page should be displayed.
    /// - Returns: `true` if the What's New page should be shown; otherwise, `false`.
    var shouldShowWhatsNewPage: Bool {
        guard EcosiaInstallType.get() == .upgrade else {
            markPreviousVersionsAsSeen()
            return false
        }

        // Are there items to be shown in the range?
        guard let items = try? getWhatsNewItemsInRange(), !items.isEmpty else { return false }

        let shownVersions = User.shared.whatsNewItemsVersionsShown
        let versionsInRange = getVersionRange().map { $0.description }

        // Are all versions in the range contained in the shown versions?
        let allVersionsShown = Set(versionsInRange).subtracting(shownVersions).isEmpty

        return !allVersionsShown
    }

    /// The current app version provider from which the Ecosia App Version is retrieved
    private(set) var versionProvider: AppVersionInfoProvider

    /// Default initializer.
    /// - Parameters:
    ///   - versionProvider: The current app version provider. Defaults to `DefaultAppVersionInfoProvider`
    ///   - whatsNewItems: The items we would like to attempt to show in the update sheet, split by version
    init(versionProvider: AppVersionInfoProvider = DefaultAppVersionInfoProvider(),
         whatsNewItems: [Version: [WhatsNewItem]] = defaultWhatsNewItems) {
        self.versionProvider = versionProvider
        self.whatsNewItems = whatsNewItems
    }

    /// The items we would like to attempt to show in the update sheet
    private var whatsNewItems: [Version: [WhatsNewItem]]

    private static let defaultWhatsNewItems = [
        Version("9.0.0")!: [
            WhatsNewItem(image: UIImage(named: "tree"),
                         title: .localized(.whatsNewFirstItemTitle9_0_0),
                         subtitle: .localized(.whatsNewFirstItemDescription9_0_0)),
            WhatsNewItem(image: UIImage(named: "customisation"),
                         title: .localized(.whatsNewSecondItemTitle9_0_0),
                         subtitle: .localized(.whatsNewSecondItemDescription9_0_0))
        ],
        Version("10.0.0")!: [
            WhatsNewItem(image: UIImage(named: StandardImageIdentifiers.Large.pageZoom),
                         title: .localized(.whatsNewFirstItemTitle10_0_0),
                         subtitle: .localized(.whatsNewFirstItemDescription10_0_0)),
            WhatsNewItem(image: UIImage(named: StandardImageIdentifiers.Large.lock),
                         title: .localized(.whatsNewSecondItemTitle10_0_0),
                         subtitle: .localized(.whatsNewSecondItemDescription10_0_0))
        ]
    ]

    /// Fetches an array of What's New items to display.
    ///
    /// - Throws: An error if fetching fails.
    ///
    /// - Returns: An array of `WhatsNewItem` to display.
    func getWhatsNewItemsInRange() throws -> [WhatsNewItem] {
        // Get the version range and corresponding What's New items.
        let versionRange = getVersionRange()
        var items: [WhatsNewItem] = []
        for version in versionRange {
            if let newItems = whatsNewItems[version] {
                items.append(contentsOf: newItems)
            }
        }
        return items
    }

    /// Private helper to fetch version range.
    ///
    /// - Returns: An array of `Version` between from and to, inclusive.
    func getVersionRange() -> [Version] {

        // Ensure `fromVersion` is available; otherwise, return an empty version range.
        guard let fromVersion else { return [] }

        // Gather all versions
        let allVersions = Array(whatsNewItems.keys).sorted()

        // Find the index of the version immediately after `fromVersion`
        guard let fromIndex = allVersions.firstIndex(where: { $0 > fromVersion }) else { return [] }

        // Find the index of the version immediately before or equal to `toVersion`
        guard let toIndex = allVersions.lastIndex(where: { $0 <= toVersion }) else { return [] }

        // Return the range between `fromIndex` (excluded) and `toIndex` (included)
        return Array(allVersions[fromIndex..<toIndex + 1])
    }

    func markPreviousVersionsAsSeen() {
        let previousVersions = whatsNewItems.keys
            .filter { $0 <= toVersion }
            .map { $0.description }
        User.shared.whatsNewItemsVersionsShown.formUnion(previousVersions)
    }
}
