// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol WKReaderModeDelegate: AnyObject {
    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didChangeReaderModeState state: ReaderModeState,
        forSession session: EngineSession
    )
    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didDisplayReaderizedContentForSession session: EngineSession
    )
    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didParseReadabilityResult readabilityResult: ReadabilityResult,
        forSession session: EngineSession
    )
}
