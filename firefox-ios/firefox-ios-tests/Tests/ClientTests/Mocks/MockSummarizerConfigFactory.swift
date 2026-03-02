// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
import WebKit
@testable import Client

final class MockSummarizerConfigFactory: SummarizerConfigFactory, @unchecked Sendable {
    var returnedConfig: SummarizerConfig?
    private(set) var makeConfigurationCallCount = 0

    func makeConfiguration(from webView: WKWebView) async -> SummarizerConfig? {
        makeConfigurationCallCount += 1
        return returnedConfig
    }
}
