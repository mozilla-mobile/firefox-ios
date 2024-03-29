// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The engine used to create an `EngineView` and `EngineSession`.
/// There is only when engine view to be created, but multiple sessions can exists.
public protocol Engine {
    /// Creates a new view for rendering web content.
    func createView() -> EngineView

    /// Creates a new engine session.
    func createSession(dependencies: EngineSessionDependencies?) throws -> EngineSession
}
