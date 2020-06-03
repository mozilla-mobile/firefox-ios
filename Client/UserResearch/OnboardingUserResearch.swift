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
    init(lpVariable: LPVar? = LPVariables.showOnboardingScreenAB) {
        self.lpVariable = lpVariable
    }
    
    // MARK: public
    func lpVariableObserver() {
        // Condition: Leanplum is disabled
        // If leanplum is not enabled then we set the value of onboarding research to true
        // True = .variant 1 which is our default Intro View
        // False = .variant 2 which is our new Intro View that we are A/B testing against
        // and get that from the server
        guard LeanPlumClient.shared.getSettings() != nil else {
            self.updateValue(onboardingScreenType: .versionV1)
            self.updatedLPVariable?()
            return
        }
        // Condition: Update from leanplum server
        // Get the A/B test variant from leanplum server
        // and update onboarding user reasearch
        LeanPlumClient.shared.finishedStartingLeanplum = {
            let showScreenA = LPVariables.showOnboardingScreenAB?.boolValue()
            LeanPlumClient.shared.finishedStartingLeanplum = nil
            self.updateTelemetry()
            let screenType: OnboardingScreenType = (showScreenA ?? true) ? .versionV1 : .versionV2
            self.updateValue(onboardingScreenType: screenType)
            self.updatedLPVariable?()
        }
        // Conditon: Leanplum server too slow
        // We don't want our users to be stuck on Onboarding
        // Wait 2 second and update the onboarding research variable
        // with true (True = .variant 1)
        // Ex. Internet connection is unstable due to which
        // leanplum isn't loading or taking too much time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard LeanPlumClient.shared.finishedStartingLeanplum != nil else {
                return
            }
            let lpStartStatus = LeanPlumClient.shared.startCallFinished
            var lpVariableValue: OnboardingScreenType = .versionV1
            // Condition: LP has already started but we missed onStartLPVariable callback
            if lpStartStatus, let boolValue = LPVariables.showOnboardingScreenAB?.boolValue() {
                lpVariableValue = boolValue ? .versionV1 : .versionV2
                self.updateTelemetry()
            }
            self.updatedLPVariable = nil
            self.updateValue(onboardingScreenType: lpVariableValue)
            self.updatedLPVariable?()
        }
    }
    
    func updateValue(onboardingScreenType: OnboardingScreenType) {
        // For LP variable below is the convention
        // we are going to follow
        // True = Current Onboarding Screen
        // False = New Onboarding Screen
        self.onboardingScreenType = onboardingScreenType
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
