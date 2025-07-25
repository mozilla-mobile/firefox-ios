// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(FoundationModels)
import Common
import Foundation
import FoundationModels
import Shared

protocol LanguageModelProtocol {
    var isAvailable: Bool { get }
}

@available(iOS 26, *)
extension SystemLanguageModel: LanguageModelProtocol { }

/// Utility for capturing apple intelligence availability
struct AppleIntelligenceUtil {
    private let userDefaults: UserDefaultsInterface

    init(userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    var isAppleIntelligenceAvailable: Bool {
        userDefaults.bool(forKey: PrefsKeys.appleIntelligenceAvailable)
    }

    @available(iOS 26.0, *)
    func processAvailabilityState(_ model: LanguageModelProtocol = SystemLanguageModel.default) {
        let isAvailable = checkAppleIntelligenceAvailability(with: model)
        userDefaults.set(isAvailable, forKey: PrefsKeys.appleIntelligenceAvailable)
    }

    @available(iOS 26, *)
    private func checkAppleIntelligenceAvailability(with model: LanguageModelProtocol) -> Bool {
        return model.isAvailable
    }
}
#endif
