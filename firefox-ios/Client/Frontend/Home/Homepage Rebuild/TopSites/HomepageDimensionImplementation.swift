// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct HomepageDimensionCalculator {
    static func isCompactLayout(
        traitCollection: UITraitCollection,
        for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        and isLandscape: Bool = UIWindow.isLandscape
    ) -> Bool {
        let isPhoneInLandscape = device == .phone && isLandscape
        return traitCollection.horizontalSizeClass == .compact && !isPhoneInLandscape
    }

    static func isMediumLayout(
        for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        and isLandscape: Bool = UIWindow.isLandscape
    ) -> Bool {
        let isPhoneInLandscape = device == .phone && isLandscape
        let isPadInPortrait = device == .pad && !isLandscape
        let isSplitMode = isPadInLandscapeSplit(
            split: 2/3,
            isLandscape: isLandscape,
            device: device
        ) &&  isPadInLandscapeSplit(
            split: 1/2,
            isLandscape: isLandscape,
            device: device
        )

        return isPhoneInLandscape || isPadInPortrait || isSplitMode
    }

    private static var isMultitasking: Bool {
        guard let window = UIWindow.keyWindow else { return false }

        return window.frame.width != window.screen.bounds.width && window.frame.width != window.screen.bounds.height
    }

    private static func isPadInLandscapeSplit(
        split: CGFloat,
        isLandscape: Bool,
        device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> Bool {
        guard device == .pad,
              isLandscape,
              isMultitasking,
              let window = UIWindow.keyWindow
        else { return false }

        let splitScreenWidth = window.screen.bounds.width * split
        return window.frame.width >= splitScreenWidth * 0.9 && window.frame.width <= splitScreenWidth * 1.1
    }

    /// Retrieves the layout configuration for the "Jump Back In" section
    /// based on the given traits, device type, and orientation.
    /// - Parameters:
    ///   - traitCollection: The trait collection of the current user interface, used to determine layout properties.
    ///   - device: The user interface idiom of the device (e.g., `.phone` or `.pad`).
    ///   - isLandscape: A Boolean indicating whether the device is in landscape orientation.
    /// - Returns: A `JumpBackInSectionLayoutConfiguration` instance defining the number of tabs and layout type.
    static func retrieveJumpBackInDisplayInfo(
        traitCollection: UITraitCollection,
        for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        and isLandscape: Bool = UIWindow.isLandscape
    ) -> JumpBackInSectionLayoutConfiguration {
        let isCompactLayout = isCompactLayout(traitCollection: traitCollection, for: device, and: isLandscape)
        let isMediumLayout = isMediumLayout(for: device, and: isLandscape)

        if isCompactLayout {
            return JumpBackInSectionLayoutConfiguration(
                maxLocalTabsWhenSyncedTabExists: 1,
                maxLocalTabsWhenNoSyncedTab: 2,
                layoutType: .compact
            )
        } else if isMediumLayout {
            return JumpBackInSectionLayoutConfiguration(
                maxLocalTabsWhenSyncedTabExists: 2,
                maxLocalTabsWhenNoSyncedTab: 4,
                layoutType: .medium
            )
        } else {
            return JumpBackInSectionLayoutConfiguration(
                maxLocalTabsWhenSyncedTabExists: 4,
                maxLocalTabsWhenNoSyncedTab: 6,
                layoutType: .regular
            )
        }
    }

    /// Updates the number of tiles (top sites) per row the user will see. This depends on the UI interface the user has.
    /// - Parameter availableWidth: available width size depending on device
    /// - Parameter leadingInset: padding for top site section
    /// - Parameter cellWidth: width of individual top site tiles
    static func numberOfTopSitesPerRow(availableWidth: CGFloat, leadingInset: CGFloat) -> Int {
        let cellWidth = HomepageSectionLayoutProvider.UX.TopSitesConstants.cellEstimatedSize.width
        var availableWidth = availableWidth - leadingInset * 2
        var numberOfTiles = 0

        while availableWidth > cellWidth {
            numberOfTiles += 1
            availableWidth = availableWidth - cellWidth - HomepageSectionLayoutProvider.UX.standardSpacing
        }
        let minCardsConstant = HomepageSectionLayoutProvider.UX.TopSitesConstants.minCards
        let tilesPerRowCount = numberOfTiles < minCardsConstant ? minCardsConstant : numberOfTiles

        return tilesPerRowCount
    }
}
