// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Used to store crash information to determine if the user crashed in the last 3 days
protocol CrashTracker {
    var hasCrashedInLast3Days: Bool { get }
    func updateData(currentDate: Date)
}

extension CrashTracker {
    func updateData(currentDate: Date = Date()) {
        updateData(currentDate: currentDate)
    }
}

struct DefaultCrashTracker: CrashTracker {
    private let logger: Logger
    private let userDefaults: UserDefaultsInterface

    enum UserDefaultsKey: String {
        case keyLastCrashDateKey = "com.moz.lastCrashDateKey.key"
    }

    /// Initializes the `DefaultCrashTracker`
    ///
    /// - Parameters:
    ///   - logger: Logger protocol to override in Unit tests
    ///   - userDefaults: UserDefaultsInterface to override in Unit tests
    init(logger: Logger = DefaultLogger.shared,
         userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.logger = logger
        self.userDefaults = userDefaults
    }

    /// Update rating prompt data
    func updateData(currentDate: Date = Date()) {
        if logger.crashedLastLaunch {
            userDefaults.set(currentDate, forKey: UserDefaultsKey.keyLastCrashDateKey.rawValue)
        }
    }

    var hasCrashedInLast3Days: Bool {
        guard let lastCrashDate = userDefaults.object(
            forKey: UserDefaultsKey.keyLastCrashDateKey.rawValue
        ) as? Date else { return false }

        let threeDaysAgo = Date(timeIntervalSinceNow: -(3 * 24 * 60 * 60))
        return lastCrashDate >= threeDaysAgo
    }
}
