// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

struct SeedCounterNTPExperiment {
    private enum Variant: String {
        case control
        case test
    }

    private init() {}

    static var progressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self

    static var isEnabled: Bool {
        Unleash.isEnabled(.seedCounterNTP) &&
        variant != .control &&
        SeedCounterNTPExperiment.seedCounterConfig != nil
    }

    private static var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.seedCounterNTP).name) ?? .control
    }

    // MARK: Analytics

    static func trackSeedCollectionIfNewDayAppOpening() {
        let seedCollectionExperimentIdentifier = "seedCollectionNTPExperimentIdentifier"
        guard Analytics.hasDayPassedSinceLastCheck(for: seedCollectionExperimentIdentifier) else {
            return
        }
        Analytics.shared.ntpSeedCounterExperiment(.collect,
                                                  value: 1)
        UserDefaults.standard.setValue(true, forKey: seedCollectionExperimentIdentifier)
    }

    static func trackTapOnSeedCounter() {
        Analytics.shared.ntpSeedCounterExperiment(.click,
                                                  value: progressManagerType.loadTotalSeedsCollected() as NSNumber)
    }

    static func trackSeedLevellingUp() {
        Analytics.shared.ntpSeedCounterExperiment(.level,
                                                  value: progressManagerType.loadCurrentLevel() as NSNumber)
    }

    static var seedCounterConfig: SeedCounterConfig? {
        guard let payloadString = Unleash.getVariant(.seedCounterNTP).payload?.value,
              let payloadData = payloadString.data(using: .utf8),
              let seedCounterConfig = try? JSONDecoder().decode(SeedCounterConfig.self, from: payloadData)
        else {
            return nil
        }
        return seedCounterConfig
    }

    static var sparklesAnimationDuration: Double {
        seedCounterConfig?.sparklesAnimationDuration ?? 0.0
    }
}
