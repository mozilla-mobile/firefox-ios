// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

/// A utility for evaluating a Nimbus feature based on a set of valid JEXLs.
/// Adaptable to any Nimbus feature by implementing a variable of type
///  `Map<String, String>` and adding respective fields to required objects.
class NimbusMessagingEvaluationUtility {
    /// Checks whether a message is eligible to be show by evaluating message JEXLs.
    func isMessageEligible(
        _ message: GleanPlumbMessage,
        messageHelper: NimbusMessagingHelperProtocol,
        jexlCache: inout [String: Bool]
    ) throws -> Bool {
        return try isNimbusElementEligible(checking: message.triggers,
                                           using: messageHelper,
                                           and: &jexlCache)
    }

    /// Checks whether an object with a generic ``[String]`` lookup table of valid
    /// JEXLs is eligible to be show by evaluating those JEXLs.
    func doesObjectMeet(
        verificationRequirements lookupTable: [String],
        using helper: NimbusMessagingHelperProtocol,
        and jexlCache: inout [String: Bool]
    ) throws -> Bool {
        return try isNimbusElementEligible(checking: lookupTable,
                                           using: helper,
                                           and: &jexlCache)
    }

    private func isNimbusElementEligible(
        checking triggers: [String],
        using helper: NimbusMessagingHelperProtocol,
        and jexlCache: inout [String: Bool]
    ) throws -> Bool {
        return try triggers.reduce(true) { accumulator, trigger in
            guard accumulator else { return false }

            // Check the jexlCache for the `Bool`, in the case we already
            // evaluated it. Otherwise, perform an expensive Foreign Function
            // Interface (FFI) operation once for the trigger.
            guard let evaluation = jexlCache[trigger] else {
                let evaluation = try helper.evalJexl(expression: trigger)
                jexlCache[trigger] = evaluation
                return evaluation
            }

            return evaluation
        }
    }
}
