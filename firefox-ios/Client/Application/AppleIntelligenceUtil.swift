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

    var cannotUseAppleIntelligence: Bool {
        userDefaults.bool(forKey: PrefsKeys.cannotRunAppleIntelligence)
    }

    @available(iOS 26.0, *)
    func processAvailabilityState(_ model: LanguageModelProtocol = SystemLanguageModel.default) {
        let isAvailable = checkAppleIntelligenceAvailability(with: model)
        let cannotUseAppleIntelligence = checkCannotUseAppleIntelligenceModel()
        userDefaults.set(isAvailable, forKey: PrefsKeys.appleIntelligenceAvailable)
        userDefaults.set(cannotUseAppleIntelligence, forKey: PrefsKeys.cannotRunAppleIntelligence)
    }

    @available(iOS 26, *)
    private func checkAppleIntelligenceAvailability(with model: LanguageModelProtocol) -> Bool {
        if AppConstants.isSkippingAppleIntelligence {
            return false
        } else {
            return model.isAvailable
        }
    }

    @available(iOS 26.0, *)
    private func checkCannotUseAppleIntelligenceModel() -> Bool {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available, .unavailable(.appleIntelligenceNotEnabled), .unavailable(.modelNotReady):
            return false
        case .unavailable(.deviceNotEligible), .unavailable:
            return true
        }
    }
}
#endif
