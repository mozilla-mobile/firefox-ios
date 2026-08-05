// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Abstraction over closing iPad windows (`UIScene`s). Lets the merge-windows feature be unit tested
/// without depending on the non-mockable `UIApplication` scene-session APIs.
protocol SceneDestroying {
    /// Requests that the iPad windows matching the given UUIDs be closed by the system.
    /// - Parameters:
    ///   - windowUUIDs: the UUIDs of the windows to close.
    ///   - errorHandler: invoked on the main thread for each window that iOS declined to close,
    ///   with the UUID of that window. Not called for windows that close successfully.
    @MainActor
    func destroyScenes(for windowUUIDs: [WindowUUID],
                       errorHandler: @escaping @MainActor (WindowUUID, any Error) -> Void)
}

struct DefaultSceneDestroyer: SceneDestroying {
    @MainActor
    func destroyScenes(for windowUUIDs: [WindowUUID],
                       errorHandler: @escaping @MainActor (WindowUUID, any Error) -> Void) {
        guard !windowUUIDs.isEmpty else { return }
        for scene in UIApplication.shared.connectedScenes {
            guard let delegate = scene.delegate as? SceneDelegate,
                  let uuid = delegate.sceneCoordinator?.windowUUID,
                  windowUUIDs.contains(uuid)
            else { continue }
            UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil) { error in
                ensureMainThread {
                    errorHandler(uuid, error)
                }
            }
        }
    }
}
