// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

/// The Message Helper is responsible for preparing fetched messages to appear in a UI surface.
/// It should do all operations on a message and return only valid, eligible, non-expired messages FOR the associated surface.
class GleanPlumbHelper: Loggable {

    // MARK: - Public helpers

    func createGleanPlumbHelper() -> GleanPlumbMessageHelper? {
        let contextProvider = GleanPlumbContextProvider()

        /// Create our GleanPlumbMessageHelper, to evaluate triggers later.
        do {
            return try Experiments.shared.createMessageHelper(additionalContext: contextProvider.createAdditionalDeviceContext())
        } catch {
            /// If we're here, then all of Messaging is in limbo! Report the error and let the surface handle this `nil`
            browserLog.error("GleanPlumbMessageHelper could not be created! With error \(error)")
            return nil
        }

    }

    /// We check whether this message is triggered by evaluating message JEXLs.
    func isMessageEligible(_ message: GleanPlumbMessage, messageHelper: GleanPlumbMessageHelper) throws -> Bool {
        try message.triggers.reduce(true) { accumulator, trigger in
            guard accumulator else { return false }

            return try messageHelper.evalJexl(expression: trigger)
        }
    }

    func checkExpiryFor(_ message: GleanPlumbMessage) -> Bool {
        return message.metadata.isExpired || (message.metadata.impressions >= message.style.maxDisplayCount)
    }

    /// If the message is under experiment, the call site needs to handle it in a special way.
    func isMessageUnderExperiment(experimentKey: String?, message: GleanPlumbMessage) -> Bool {
        guard let experimentKey = experimentKey else { return false }

        if message.data.isControl { return true }

        if message.id.hasSuffix("-") {
            return message.id.hasPrefix(experimentKey)
        }

        return message.id == experimentKey
    }

}
