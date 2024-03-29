// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebEngine

struct EngineProvider {
    // We only have one session in the SampleBrowser
    private(set) var session: EngineSession?
    let view: EngineView

    init(engine: Engine = WKEngine.factory(),
         sessionDependencies: EngineSessionDependencies? = nil) {
        do {
            session = try engine.createSession(dependencies: sessionDependencies)
        } catch {
            session = nil
        }

        view = engine.createView()
    }
}
