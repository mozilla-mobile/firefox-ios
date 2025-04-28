// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum ZoomLevel: CGFloat, CaseIterable {
    case fiftyPercent = 0.5
    case seventyFivePercent = 0.75
    case ninetyPercent = 0.9
    case oneHundredPercent = 1.0
    case oneHundredTenPercent = 1.10
    case oneHundredTwentyFivePercent = 1.25
    case oneHundredFiftyPercent = 1.5
    case oneHundredSeventyFivePercent = 1.75
    case twoHundred = 2.0

    /// Returns the next higher zoom level based on the given current zoom level.
    /// If the current level is at or above the upper zoom limit (`ZoomConstants.upperZoomLimit`),
    /// it will return the same level without change.
    /// 
    /// - Parameter level: The current zoom level as a `CGFloat`.
    /// - Returns: The next zoom level as a `CGFloat`, or the current level if already at the maximum limit.
    static func getNewZoomInLevel(for level: CGFloat) -> CGFloat {
        let zoomLevels = self.allCases

        guard let currentLevel = zoomLevels.first(where: { $0.rawValue == level }),
              let currentIndex = zoomLevels.firstIndex(of: currentLevel),
              level < ZoomConstants.upperZoomLimit else { return level }

        return zoomLevels[currentIndex + 1].rawValue
    }

    /// Returns the next lower zoom level based on the given current zoom level.
    /// If the current level is at or below the lower zoom limit (`ZoomConstants.lowerZoomLimit`),
    /// it will return the same level without change.
    ///
    /// - Parameter level: The current zoom level as a `CGFloat`.
    /// - Returns: The previous zoom level as a `CGFloat`, or the current level if already at the minimum limit.
    static func getNewZoomOutLevel(for level: CGFloat) -> CGFloat {
        let zoomLevels = self.allCases

        guard let currentLevel = zoomLevels.first(where: { $0.rawValue == level }),
              let currentIndex = zoomLevels.firstIndex(of: currentLevel),
              level > ZoomConstants.lowerZoomLimit else { return level }

        return zoomLevels[currentIndex - 1].rawValue
    }
}
