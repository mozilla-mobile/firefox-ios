// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

@testable import Client

@MainActor
final class MockPasswordGeneratorScriptEvaluator: PasswordGeneratorScriptEvaluator {
    var evaluateScriptCalled = 0
    var lastEvaluatedScript: String?
    var lastEvaluatedFrame: WKFrameInfo?

    // Configurable response
    var resultToReturn: Any?
    var errorToReturn: Error?

    func evaluateJavascriptInDefaultContentWorld(_ javascript: String,
                                                 _ frame: WKFrameInfo?,
                                                 _ completion: @escaping @MainActor (Any?, (any Error)?) -> Void) {
        evaluateScriptCalled += 1
        lastEvaluatedScript = javascript
        lastEvaluatedFrame = frame
        completion(resultToReturn, errorToReturn)
    }
}
