// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WKEngine: Engine {
    private let userScriptManager: WKUserScriptManager

    init(userScriptManager: WKUserScriptManager = DefaultUserScriptManager()) {
        self.userScriptManager = userScriptManager
    }

    func createView() -> EngineView {
        return WKEngineView(frame: .zero)
    }

    func createSession() throws -> EngineSession {
        guard let session = WKEngineSession(userScriptManager: userScriptManager) else {
            throw EngineError.sessionNotCreated
        }

        return session
    }
}
