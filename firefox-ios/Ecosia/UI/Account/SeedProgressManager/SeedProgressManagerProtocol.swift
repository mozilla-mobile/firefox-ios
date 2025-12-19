// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol SeedProgressManagerProtocol {
    static var progressUpdatedNotification: Notification.Name { get }
    static var levelUpNotification: Notification.Name { get }
    static var seedCounterConfig: SeedCounterConfig? { get set }

    static func loadCurrentLevel() -> Int
    static func loadTotalSeedsCollected() -> Int
    static func loadLastAppOpenDate() -> Date?

    static func saveProgress(totalSeeds: Int, currentLevel: Int, lastAppOpenDate: Date)

    static func addSeeds(_ count: Int, relativeToDate date: Date)
    static func resetLocalSeedProgress()

    static func calculateInnerProgress() -> CGFloat
    static func collectDailySeed()
}
