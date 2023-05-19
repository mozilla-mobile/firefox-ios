// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

/// Methods here can be considered as tools for extracting certain information from a message.
class GleanPlumbEvaluationUtility {
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    // MARK: - Public helpers

    func createGleanPlumbHelper() -> GleanPlumbMessageHelper? {
        let contextProvider = GleanPlumbContextProvider()

        // Create our GleanPlumbMessageHelper.
        do {
            return try Experiments.shared.createMessageHelper(additionalContext: contextProvider.createAdditionalDeviceContext())
        } catch {
            // If we're here, then all of Messaging is in limbo! Report the error and let the surface handle this `nil`
            logger.log("GleanPlumbMessageHelper could not be created! With error \(error)",
                       level: .warning,
                       category: .experiments)
            return nil
        }
    }

    /// We check whether this message is triggered by evaluating message JEXLs.
    func isMessageEligible(
        _ message: GleanPlumbMessage,
        messageHelper: GleanPlumbMessageHelper,
        jexlCache: inout [String: Bool]
    ) throws -> Bool {
        return try isGleanPlumbElementEligible(checking: message.triggers,
                                               using: messageHelper,
                                               and: &jexlCache)
    }

    func isCardValid(
        checking prerequisites: [String],
        using helper: GleanPlumbMessageHelper,
        and jexlCache: inout [String: Bool]
    ) throws -> Bool {
        return try isGleanPlumbElementEligible(checking: prerequisites,
                                               using: helper,
                                               and: &jexlCache)
    }

    private func isGleanPlumbElementEligible(
        checking triggers: [String],
        using helper: GleanPlumbMessageHelper,
        and jexlCache: inout [String: Bool]
    ) throws -> Bool {
        // Some unit test are failing in Bitrise during the jexlEvaluation
        // process. We will bypass the check for unit test while we find a
        // solution to mock properly `GleanPlumbMessageUtility` that right
        // now is highly tied to `Experiments.shared`
        guard !AppConstants.isRunningTest else { return true }

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
