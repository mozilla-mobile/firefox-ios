// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices

// Contextual identifier used for the sponsored tiles in top sites and the suggestions in the search view
class ContextIDManager {
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

    private var contextIDComponent: ContextIdComponentProtocol?

    static let shared = ContextIDManager()

    static func setup(
        isGleanMetricsAllowed allowed: Bool,
        isTesting: Bool,
        contextIdComponent: ContextIdComponentProtocol? = nil
    ) {
        shared.contextIDComponent = contextIdComponent ?? shared.setupContextId(
            isGleanMetricsAllowed: allowed,
            isTesting: isTesting
        )
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

    func clearContextIDState() {
        do {
            // TODO: if we don't have multiprofiles do we still need to unset the call back on App death
            try contextIDComponent?.unsetCallback()
        } catch {
            // catch error
        }
    }

    func setContextID(_ contextID: String?, creationTimestamp: Int64?) {
        ContextIDStorage.setContextID(contextID, creationTimestamp: creationTimestamp)
    }

    private func setupContextId(isGleanMetricsAllowed allowed: Bool, isTesting: Bool) -> ContextIdComponentProtocol? {
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
