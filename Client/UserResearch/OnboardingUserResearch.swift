/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Leanplum

struct LPVariables {
    static var showOnboardingScreen = LPVar.define("showOnboardingScreen", with: true)
}

class OnboardingUserResearch {
    // Delegate closure
    var updatedLPVariables: ((LPVar?) -> Void)?
    // variable
    var lpVariable: LPVar?
    
    // Initializer
    init(lpVariable: LPVar? = LPVariables.showOnboardingScreen) {
        self.lpVariable = lpVariable
    }
    
    func lpVariableObserver() {
        Leanplum.onVariablesChanged {
            self.updatedLPVariables?(self.lpVariable)
        }
    }
}
