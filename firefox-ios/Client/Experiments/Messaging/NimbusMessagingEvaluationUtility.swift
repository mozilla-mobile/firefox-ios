// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import protocol MozillaAppServices.NimbusMessagingHelperProtocol

/// A utility for evaluating a Nimbus feature based on a set of valid JEXLs.
/// Adaptable to any Nimbus feature by implementing a variable of type
///  `Map<String, String>` and adding respective fields to required objects.
class NimbusMessagingEvaluationUtility {
    /// Checks whether a message is eligible to be show by evaluating message JEXLs.
    func isMessageEligible(
        _ message: GleanPlumbMessage,
        messageHelper: NimbusMessagingHelperProtocol
    ) throws -> Bool {
        return try isNimbusElementEligible(checking: message.triggerIfAll,
                                           except: message.exceptIfAny,
                                           using: messageHelper)
    }

    /// Checks whether an object with a generic ``[String]`` lookup table of valid
    /// JEXLs is eligible to be show by evaluating those JEXLs.
    func doesObjectMeet(
        verificationRequirements lookupTable: [String],
        using helper: NimbusMessagingHelperProtocol
    ) throws -> Bool {
        return try isNimbusElementEligible(checking: lookupTable,
                                           using: helper)
    }

    private func isNimbusElementEligible(
        checking triggerIfAll: [String],
        except exceptIfAny: [String] = [],
        using helper: NimbusMessagingHelperProtocol
    ) throws -> Bool {
        let ifAll = try triggerIfAll.reduce(true) { accumulator, trigger in
            return try accumulator && (try helper.evalJexl(expression: trigger))
        }
        let ifAny = try exceptIfAny.reduce(false) { accumulator, trigger in
            return try accumulator || (try helper.evalJexl(expression: trigger))
        }
        return ifAll && !ifAny
    }
}
