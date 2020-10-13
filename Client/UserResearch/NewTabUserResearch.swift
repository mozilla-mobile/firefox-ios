/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Leanplum
import Shared

class NewTabUserResearch {
    // Variable
    var lpVariable: LPVar?
    // Constants
    private let enrollmentKey = "newTabUserResearchEnrollmentKey"
    private let newTabUserResearchKey = "newTabUserResearchKey"
    // Saving user defaults
    private let defaults = UserDefaults.standard
    // LP fetched status variable
    private var fetchedExperimentVariables = false
    // New tab button state
    // True: Show new tab button
    // False: Hide new tab button
    var newTabState: Bool? {
        set(value) {
            if value == nil {
                defaults.removeObject(forKey: newTabUserResearchKey)
            } else {
                defaults.set(value, forKey: newTabUserResearchKey)
            }
        }
        get {
            guard let value = defaults.value(forKey: newTabUserResearchKey) as? Bool else {
                return nil
            }
            return value
        }
    }
    var hasEnrolled: Bool {
        set(value) {
            defaults.set(value, forKey: enrollmentKey)
        }
        get {
            defaults.bool(forKey: enrollmentKey)
        }
    }
    
    // MARK: Initializer
    init(lpVariable: LPVar? = LPVariables.newTabButtonABTest) {
        self.lpVariable = lpVariable
    }
    
    // MARK: public
    func lpVariableObserver() {
        // Condition: Leanplum is disabled; Set default New tab state
        guard LeanPlumClient.shared.getSettings() != nil else {
            // default state is false
            self.newTabState = false
            return
        }
        // Condition: A/B test variables from leanplum server
        LeanPlumClient.shared.finishedStartingLeanplum = {
            LeanPlumClient.shared.finishedStartingLeanplum = nil
            guard self.fetchedExperimentVariables == false else {
                return
            }
            self.fetchedExperimentVariables = true
            //Only update add new tab (+ button) when it doesn't match leanplum value 
            let lpValue = LPVariables.newTabButtonABTest?.boolValue() ?? false
            if self.newTabState != lpValue {
                self.newTabState = lpValue
                self.updateTelemetry()
            }
        }
        // Condition: Leanplum server too slow; Set default New tab state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard self.fetchedExperimentVariables == false && self.newTabState == nil else {
                return
            }
            // Condition: Leanplum server too slow; Set default New tab state
            self.newTabState = false
            // Condition: LP has already started but we missed onStartLPVariable callback
            if case .started(startedState: _) = LeanPlumClient.shared.lpState , let boolValue = LPVariables.newTabButtonABTest?.boolValue() {
                self.newTabState = boolValue
                self.updateTelemetry()
            }
            self.fetchedExperimentVariables = true
        }
    }
    
    func updateTelemetry() {
        guard !hasEnrolled else { return }
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
        hasEnrolled = true
    }
}
