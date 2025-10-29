// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol ShareTab: Sendable {
    @MainActor
    var displayTitle: String { get }
    @MainActor
    var url: URL? { get }
    @MainActor
    var canonicalURL: URL? { get }
    @MainActor
    var webView: TabWebView? { get }

    // Tabs displaying content other than HTML mime type can optionally be downloaded and treated as files when shared
    @MainActor
    var temporaryDocument: TemporaryDocument? { get }
}
