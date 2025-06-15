// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices

class ContextIDRotationHandler: ContextIdCallback {
    private let isGleanMetricsAllowed: Bool
    private let gleanWrapper: GleanWrapper

    init(isGleanMetricsAllowed: Bool, gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.isGleanMetricsAllowed = isGleanMetricsAllowed
        self.gleanWrapper = gleanWrapper
    }

    func persist(contextId: String, creationDate: Int64) {
        ContextIDManager.shared.setContextID(contextId, creationTimestamp: creationDate)
        guard isGleanMetricsAllowed else { return }
        guard let uuid = UUID(uuidString: contextId) else {
            // log error
            return
        }
        // TODO: Does this still make sense here?
        gleanWrapper.setUUID(for: GleanMetrics.TopSites.contextId, value: uuid)
    }

    func rotated(oldContextId: String) {
        guard let contextUUID = UUID(uuidString: oldContextId) else {
            // log error
            return
        }
        gleanWrapper.setPingBoolean(for: GleanMetrics.Pings.shared.contextIdDeletionRequest, value: true)
        gleanWrapper.setUUID(for: GleanMetrics.ContextualServices.contextId, value: contextUUID)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.contextIdDeletionRequest)
    }
}
