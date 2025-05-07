// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The engine used to create an `EngineView` and `EngineSession`.
/// There is only when engine view to be created, but multiple sessions can exists.
public protocol Engine {
    /// Creates a new view for rendering web content.
    /// - Returns: The created `EngineView`
    func createView() -> EngineView

    /// Creates a new engine session.
    /// - Parameter dependencies: Pass in the required session dependencies on creation
    /// - Returns: The created `EngineSession`
    @MainActor
    func createSession(dependencies: EngineSessionDependencies) throws -> EngineSession

    /// Warm the `Engine` whenever we move the application to foreground
    func warmEngine()

    /// Idle the `Engine` whenever we move the application to background
    func idleEngine()

    // MARK: - Clearing data

    /// Clear caches whenever the user requests it's data to be cleared
    func clearCaches()

    /// Clear cookies whenever the user requests it's data to be cleared
    func clearCookies()

    /// Clear offline website data whenever the user requests it's data to be cleared
    func clearOfflineWebsiteData()

    /// Clear tracking protection whenever the user requests it's data to be cleared
    func clearTrackingProtection()
}
