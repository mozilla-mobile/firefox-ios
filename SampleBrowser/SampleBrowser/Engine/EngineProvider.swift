// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebEngine

@MainActor
struct EngineProvider {
    private var engine: Engine
    // We only have one session and one view in the SampleBrowser so this code is very simple
    private(set) var session: EngineSession
    private(set) var view: EngineView

    init?(dependencyManager: EngineDependencyManager) async {
        self.engine = WKEngine.factory(engineDependencies: dependencyManager.engineDependencies)

        do {
            session = try await engine.createSession(dependencies: dependencyManager.sessionDependencies)
        } catch {
            return nil
        }

        view = engine.createView()
    }

    func warmEngine() {
        engine.warmEngine()
    }

    func idleEngine() {
        engine.idleEngine()
    }
}
