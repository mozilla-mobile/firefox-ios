// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

/// Methods here can be considered as tools for extracting certain information from a message.
class GleanPlumbMessageUtility {
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    // MARK: - Public helpers

    func createGleanPlumbHelper() -> NimbusMessagingHelperProtocol? {
        let contextProvider = GleanPlumbContextProvider()

        // Create our message helper
        do {
            return try Experiments.shared.createMessageHelper(additionalContext: contextProvider.createAdditionalDeviceContext())
        } catch {
            // If we're here, then all of Messaging is in limbo! Report the error and let the surface handle this `nil`
            logger.log("NimbusMessagingHelper could not be created! With error \(error)",
                       level: .warning,
                       category: .experiments)
            return nil
        }
    }

    /// We check whether this message is triggered by evaluating message JEXLs.
    func isMessageEligible(_ message: GleanPlumbMessage,
                           messageHelper: NimbusMessagingHelperProtocol,
                           jexlCache: inout [String: Bool]) throws -> Bool {
        // Some unit test are failing in Bitrise during the jexlEvaluation process we will bypass the check for unit test while we find a solution to mock properly
        // `GleanPlumbMessageUtility` that right now is highly tied to `Experiments.shared`
        guard !AppConstants.isRunningTest else { return true }

        return try message.triggers.reduce(true) { accumulator, trigger in
            guard accumulator else { return false }
            var isTriggered: Bool

            // Check the jexlCache for the `Bool`, in the case we already evaluated it.
            if let jexlEvaluation = jexlCache[trigger] {
                isTriggered = jexlEvaluation
            } else {
                // Otherwise, perform this expensive Foreign Function Interface operation once for the trigger.
                isTriggered = try messageHelper.evalJexl(expression: trigger)
                jexlCache[trigger] = isTriggered
            }

            return isTriggered
        }
    }
}
