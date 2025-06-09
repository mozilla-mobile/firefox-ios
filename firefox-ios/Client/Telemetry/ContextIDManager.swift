// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices

// Contextual identifier used for the sponsored tiles in top sites and the suggestions in the search view
class ContextIDManager {
    private var contextIDComponent: ContextIdComponent?

    static let shared = ContextIDManager()

    static func setup(isGleanMetricsAllowed allowed: Bool, isTesting: Bool) {
        shared.contextIDComponent = shared.setupContextId(isGleanMetricsAllowed: allowed, isTesting: isTesting)
    }

    private struct ContextIDStorage {
        enum UserDefaultsKey: String {
            case keyContextId = "com.moz.contextId.key"
            case keyContextIdCreationTimestamp
        }

        static var contextID: String? {
            get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyContextId.rawValue) as? String }
            set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyContextId.rawValue) }
        }

        static var contextIdCreationTimeStamp: Int64? {
            get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyContextId.rawValue) as? Int64 }
            set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyContextId.rawValue) }
        }

        static func setContextID(_ contextID: String?, creationTimestamp: Int64?) {
            ContextIDStorage.contextID = contextID
            ContextIDStorage.contextIdCreationTimeStamp = creationTimestamp
        }
    }

    func getContextID() -> String? {
        do {
            // TODO: Set up rotation as a feature flag
            return try contextIDComponent?.request(rotationDaysInS: 0)
        } catch {
            // handle error
            return nil
        }
    }

    fileprivate func setContextID(_ contextID: String?, creationTimestamp: Int64?) {
        ContextIDStorage.setContextID(contextID, creationTimestamp: creationTimestamp)
    }

    private func setupContextId(isGleanMetricsAllowed allowed: Bool, isTesting: Bool) -> ContextIdComponent? {
        do {
            return try ContextIdComponent(
                initContextId: ContextIDStorage.contextID ?? "",
                creationTimestampS: ContextIDStorage.contextIdCreationTimeStamp ?? 0,
                runningInTestAutomation: isTesting,
                callback: ContextIDRotationHandler(isGleanMetricsAllowed: allowed)
            )
        } catch {
            // catch error
            return nil
        }
    }
}

class ContextIDRotationHandler: ContextIdCallback {
    private let isGleanMetricsAllowed: Bool

    init(isGleanMetricsAllowed: Bool) {
        self.isGleanMetricsAllowed = isGleanMetricsAllowed
    }

    func persist(contextId: String, creationDate: Int64) {
        ContextIDManager.shared.setContextID(contextId, creationTimestamp: creationDate)
        guard isGleanMetricsAllowed else { return }
        guard let uuid = UUID(uuidString: contextId) else {
            // log error
            return
        }
        GleanMetrics.TopSites.contextId.set(uuid)
    }

    func rotated(oldContextId: String) {
        // NO-OP
        /*
         GleanPings.contextIdDeletionRequest.setEnabled(true);
         Glean.contextualServices.contextId.set(oldContextId);
         GleanPings.contextIdDeletionRequest.submit();
         */
    }
}
