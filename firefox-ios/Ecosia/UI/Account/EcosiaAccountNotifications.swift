// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Notification names for account progress and level changes
extension Notification.Name {
    /// Posted when account progress is updated
    /// UserInfo may contain: progress (Double), level (Int)
    public static let EcosiaAccountProgressUpdated = Notification.Name("EcosiaAccountProgressUpdated")

    /// Posted when user levels up
    /// UserInfo may contain: newLevel (Int), newProgress (Double)
    public static let EcosiaAccountLevelUp = Notification.Name("EcosiaAccountLevelUp")
}

/// Keys for notification userInfo dictionaries
public struct EcosiaAccountNotificationKeys {
    public static let progress = "progress"
    public static let level = "level"
    public static let newLevel = "newLevel"
    public static let newProgress = "newProgress"
}

/// Helper class for posting account progress notifications
public final class EcosiaAccountNotificationCenter {

    /// Posts a progress updated notification
    /// - Parameters:
    ///   - progress: The new progress value (0.0 to 1.0)
    ///   - level: Optional level information
    public static func postProgressUpdated(progress: Double, level: Int? = nil) {
        var userInfo: [String: Any] = [EcosiaAccountNotificationKeys.progress: progress]
        if let level = level {
            userInfo[EcosiaAccountNotificationKeys.level] = level
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .EcosiaAccountProgressUpdated,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    /// Posts a level up notification
    /// - Parameters:
    ///   - newLevel: The new level reached
    ///   - newProgress: The new progress value (0.0 to 1.0)
    public static func postLevelUp(newLevel: Int, newProgress: Double) {
        let userInfo: [String: Any] = [
            EcosiaAccountNotificationKeys.newLevel: newLevel,
            EcosiaAccountNotificationKeys.newProgress: newProgress
        ]

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .EcosiaAccountLevelUp,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
