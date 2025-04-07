// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WKReadabilityService {
    private let ReadabilityServiceDefaultConcurrency = 1
    var queue: OperationQueue

    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = ReadabilityServiceDefaultConcurrency
    }

    func process(_ url: URL, cache: ReaderModeCache) {
        let readabilityOperation = WKReadabilityOperation(url: url,
                                                          readerModeCache: cache)

        queue.addOperation(readabilityOperation)
    }
}
