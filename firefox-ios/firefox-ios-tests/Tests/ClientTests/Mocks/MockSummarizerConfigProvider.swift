// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
@testable import Client

final class MockSummarizerConfigProvider: SummarizerConfigProvider {
    private(set) var getConfigCalledCount = 0

    func getConfig(
        from sources: [any SummarizerConfigSourceProtocol],
        summarizerModel: SummarizerModel,
        contentType: SummarizationContentType,
        locale: Locale?
    ) -> SummarizerConfig {
        getConfigCalledCount += 1
        return SummarizerConfig.defaultConfig
    }
}
