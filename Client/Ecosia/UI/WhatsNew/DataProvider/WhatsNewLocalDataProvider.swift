// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

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
    init(versionProvider: AppVersionInfoProvider = DefaultAppVersionInfoProvider()) {
        self.versionProvider = versionProvider
    }
    
    /// The items we would like to attempt to show in the update sheet
    private let whatsNewItems: [Version: [WhatsNewItem]] = [
        Version("9.0.0")!: [
            WhatsNewItem(image: UIImage(named: "tree"),
                         title: .localized(.whatsNewFirstItemTitle),
                         subtitle: .localized(.whatsNewFirstItemDescription)),
            WhatsNewItem(image: UIImage(named: "customisation"),
                         title: .localized(.whatsNewSecondItemTitle),
                         subtitle: .localized(.whatsNewSecondItemDescription))
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

        // Gather first item in `allVersions` array
        guard let firstItemInAllVersions = allVersions.first else { return [] }
        
        // Ensure the `toVersion` is greater than or equal to the smallest version in `whatsNewItems`
        guard toVersion >= firstItemInAllVersions else { return [] }

        // Find the closest previous version or use the first one if `from` is older than all versions.
        let fromIndex = allVersions.lastIndex { $0 <= fromVersion } ?? 0

        // Find the index of `to` version or the last version if `to` is newer than all versions.
        let toIndex = allVersions.firstIndex { $0 >= toVersion } ?? (allVersions.count - 1)
        
        // Return the range.
        return Array(allVersions[fromIndex...toIndex])
    }
    
    func markPreviousVersionsAsSeen() {
        let previousVersions = whatsNewItems.keys
            .filter { $0 <= toVersion }
            .map { $0.description }
        User.shared.whatsNewItemsVersionsShown.formUnion(previousVersions)
    }
}
