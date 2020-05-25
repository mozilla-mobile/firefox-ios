/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Leanplum
import Shared

struct LPVariables {
    // Variable Used for AA test
    static var showOnboardingScreenAA = LPVar.define("showOnboardingScreen", with: true)
    // Variable Used for AB test
    static var showOnboardingScreenAB = LPVar.define("showOnboardingScreen_2", with: true)
}

enum OnboardingScreenType: String {
    case versionV1 // V1 (Default)
    case versionV2 // V2
}

class OnboardingUserResearch {
    // Closure delegate
    var updatedLPVariables: ((LPVar?) -> Void)?
    // variable
    var lpVariable: LPVar?
    // Constants
    private let onboardingScreenTypeKey = "onboardingScreenTypeKey"
    // Saving user defaults
    private let defaults = UserDefaults.standard
    // Publicly accessible onboarding screen type
    var onboardingScreenType: OnboardingScreenType? {
        set(value) {
            if value == nil {
                defaults.removeObject(forKey: onboardingScreenTypeKey)
            } else {
                defaults.set(value?.rawValue, forKey: onboardingScreenTypeKey)
            }
        }
        get {
            guard let value = defaults.value(forKey: onboardingScreenTypeKey) as? String else {
                return nil
            }
            return OnboardingScreenType(rawValue: value)
        }
    }
    
    // MARK: Initializer
    init(lpVariable: LPVar? = LPVariables.showOnboardingScreenAB) {
        self.lpVariable = lpVariable
    }
    
    // MARK: public
    func lpVariableObserver() {
        Leanplum.onVariablesChanged {
            self.updatedLPVariables?(self.lpVariable)
        }
    }
    
    func updateValue(onboardingScreenType: Bool) {
        // For LP variable below is the convention
        // we are going to follow
        // True = Current Onboarding Screen
        // False = New Onboarding Screen
        self.onboardingScreenType = onboardingScreenType ? .versionV1 : .versionV2
    }
    
    func updateTelemetry() {
        // Printing variant is good to know all details of A/B test fields
        print("lp variant \(String(describing: Leanplum.variants()))")
        guard let variants = Leanplum.variants(), let lpData = variants.first as? Dictionary<String, AnyObject> else {
            return
        }
        var abTestId = ""
        if let value = lpData["abTestId"] as? Int64 {
                abTestId = "\(value)"
        }
        let abTestName = lpData["abTestName"] as? String ?? ""
        let abTestVariant = lpData["name"] as? String ?? ""
        let attributesExtras = [LPAttributeKey.experimentId: abTestId, LPAttributeKey.experimentName: abTestName, LPAttributeKey.experimentVariant: abTestVariant]
        // Leanplum telemetry
        LeanPlumClient.shared.set(attributes: attributesExtras)
        // Legacy telemetry
        UnifiedTelemetry.recordEvent(category: .enrollment, method: .add, object: .experimentEnrollment, extras: attributesExtras)
    }
}
