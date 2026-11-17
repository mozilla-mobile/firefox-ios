// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// The scene-session corner of `UIApplication`, expressed in terms of `WindowUUID` instead of
/// `UIScene`, which cannot be constructed in a test. Keeps the UIKit calls in a single leaf so that
/// the window-closing logic built on top of them can be substituted and unit tested.
protocol SceneSessionInterface {
    /// The UUIDs of the browser windows currently connected to the app.
    @MainActor
    var connectedWindowUUIDs: [WindowUUID] { get }

    /// Asks the system to close the window with the given UUID. Does nothing when no connected
    /// window has that UUID.
    /// - Parameters:
    ///   - windowUUID: the UUID of the window to close.
    ///   - errorHandler: invoked on the main thread only when iOS declines to close the window.
    @MainActor
    func requestSceneSessionDestruction(for windowUUID: WindowUUID,
                                        errorHandler: @escaping @MainActor (any Error) -> Void)
}

extension UIApplication: SceneSessionInterface {
    var connectedWindowUUIDs: [WindowUUID] {
        return connectedScenes.compactMap { windowUUID(for: $0) }
    }

    func requestSceneSessionDestruction(for windowUUID: WindowUUID,
                                        errorHandler: @escaping @MainActor (any Error) -> Void) {
        guard let scene = connectedScenes.first(where: { self.windowUUID(for: $0) == windowUUID })
        else { return }

        requestSceneSessionDestruction(scene.session, options: nil) { error in
            ensureMainThread {
                errorHandler(error)
            }
        }
    }

    private func windowUUID(for scene: UIScene) -> WindowUUID? {
        guard let delegate = scene.delegate as? SceneDelegate else { return nil }
        return delegate.sceneCoordinator?.windowUUID
    }
}
