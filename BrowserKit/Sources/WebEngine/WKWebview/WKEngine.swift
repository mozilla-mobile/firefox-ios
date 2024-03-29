// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class WKEngine: Engine {
    private let userScriptManager: WKUserScriptManager

    public static func factory() -> WKEngine {
        return WKEngine()
    }

    init(userScriptManager: WKUserScriptManager = DefaultUserScriptManager()) {
        self.userScriptManager = userScriptManager
    }

    public func createView() -> EngineView {
        return WKEngineView(frame: .zero)
    }

    public func createSession(dependencies: EngineSessionDependencies?) throws -> EngineSession {
        guard let session = WKEngineSession(userScriptManager: userScriptManager,
                                            telemetryProxy: dependencies?.telemetryProxy) else {
            throw EngineError.sessionNotCreated
        }

        return session
    }
}
