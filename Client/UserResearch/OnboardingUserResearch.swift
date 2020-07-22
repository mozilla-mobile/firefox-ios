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
    // Variable Used for 2nd Iteration of Onboarding AB Test
    static var onboardingABTestV2 = LPVar.define("onboardingABTestV2", with: true)
}

// For LP variable below is the convention we follow
// True = Current Onboarding Screen
// False = New Onboarding Screen
enum OnboardingScreenType: String {
    case versionV1
    case versionV2 
    
    static func from(boolValue: Bool) -> OnboardingScreenType {
        return boolValue ? .versionV1 : .versionV2
    }
}

class OnboardingUserResearch {
    // Closure delegate
    var updatedLPVariable: (() -> Void)?
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
    init(lpVariable: LPVar? = LPVariables.onboardingABTestV2) {
        self.lpVariable = lpVariable
    }
    
    // MARK: public
    func lpVariableObserver() {
        // Condition: Leanplum is disabled; use default intro view
        guard LeanPlumClient.shared.getSettings() != nil else {
            self.onboardingScreenType = .versionV1
            self.updatedLPVariable?()
            return
        }
        // Condition: A/B test variables from leanplum server
        LeanPlumClient.shared.finishedStartingLeanplum = {
            let showScreenA = LPVariables.onboardingABTestV2?.boolValue()
            LeanPlumClient.shared.finishedStartingLeanplum = nil
            self.updateTelemetry()
            let screenType = OnboardingScreenType.from(boolValue: (showScreenA ?? true))
            self.onboardingScreenType = screenType
            self.updatedLPVariable?()
        }
        // Condition: Leanplum server too slow; Show default onboarding.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard LeanPlumClient.shared.finishedStartingLeanplum != nil else {
                return
            }
            let lpStartStatus = LeanPlumClient.shared.lpState
            var lpVariableValue: OnboardingScreenType = .versionV1
            // Condition: LP has already started but we missed onStartLPVariable callback
            if case .started(startedState: _) = lpStartStatus , let boolValue = LPVariables.onboardingABTestV2?.boolValue() {
                lpVariableValue = boolValue ? .versionV1 : .versionV2
                self.updateTelemetry()
            }
            self.onboardingScreenType = lpVariableValue
            self.updatedLPVariable?()
        }
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
        TelemetryWrapper.recordEvent(category: .enrollment, method: .add, object: .experimentEnrollment, extras: attributesExtras)
    }
}
