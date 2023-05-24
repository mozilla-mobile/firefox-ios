// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import MozillaAppServices

protocol GleanPlumbHelperUtilityProtocol {
    func createGleanPlumbHelper() -> GleanPlumbMessageHelper?
    init(logger: Logger)
}

/// Responsible for creating a ``GleanPlumbMessageHelper`` with appropriate context.
class GleanPlumbHelperUtility: GleanPlumbHelperUtilityProtocol {
    private var logger: Logger

    required init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

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
}
