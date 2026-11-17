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
    /// Supplied by tests. Left `nil` in production and resolved to `UIApplication.shared` inside
    /// `destroyScenes`, so that building a destroyer — which happens in a `BrowserCoordinator`
    /// default argument — does not have to be main actor isolated just to read `shared`.
    private let application: SceneSessionInterface?

    init(application: SceneSessionInterface? = nil) {
        self.application = application
    }

    @MainActor
    func destroyScenes(for windowUUIDs: [WindowUUID],
                       errorHandler: @escaping @MainActor (WindowUUID, any Error) -> Void) {
        guard !windowUUIDs.isEmpty else { return }

        let sceneSessions = application ?? UIApplication.shared
        for windowUUID in sceneSessions.connectedWindowUUIDs where windowUUIDs.contains(windowUUID) {
            sceneSessions.requestSceneSessionDestruction(for: windowUUID) { error in
                errorHandler(windowUUID, error)
            }
        }
    }
}
