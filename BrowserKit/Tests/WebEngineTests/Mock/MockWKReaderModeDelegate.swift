// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
@testable import WebEngine

class MockWKReaderModeDelegate: WKReaderModeDelegate {
    var didChangeReaderModeStateCalled = 0
    var didDisplayReaderizedContentForSessionCalled = 0
    var didParseReadabilityResultCalled = 0

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didChangeReaderModeState state: ReaderModeState,
                    forSession session: EngineSession) {
        didChangeReaderModeStateCalled += 1
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didDisplayReaderizedContentForSession session: EngineSession) {
        didDisplayReaderizedContentForSessionCalled += 1
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didParseReadabilityResult readabilityResult: WebEngine.ReadabilityResult,
                    forSession session: EngineSession) {
        didParseReadabilityResultCalled += 1
    }
}
