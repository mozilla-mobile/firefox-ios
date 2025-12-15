// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

@MainActor
class MockShareTab: ShareTab {
    nonisolated let tabUUID: Client.TabUUID
    var canonicalURL: URL?
    var displayTitle: String
    var url: URL?
    var webView: TabWebView?
    var temporaryDocument: TemporaryDocument?

    init(
        title: String,
        url: URL?,
        canonicalURL: URL?,
        tabUUID: TabUUID = UUID().uuidString,
        withActiveWebView: Bool = true,
        withTemporaryDocument: TemporaryDocument? = nil
    ) {
        self.displayTitle = title
        self.url = url
        self.canonicalURL = canonicalURL
        self.tabUUID = tabUUID
        self.webView = TabWebView(frame: CGRect.zero, configuration: .init(), windowUUID: .XCTestDefaultUUID)
        self.temporaryDocument = withTemporaryDocument
    }
}
