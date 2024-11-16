// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

@testable import Client

class MockContileProvider: ContileProviderInterface {
    enum MockError: Error {
        case testError
    }

    private var result: ContileResult

    static var emptySuccessData: [Contile] = []

    static var defaultSuccessData: [Contile] {
        return [
            Contile(id: 1,
                    name: "Firefox Sponsored Tile",
                    url: "https://firefox.com",
                    clickUrl: "https://firefox.com/click",
                    imageUrl: "https://test.com/image1.jpg",
                    imageSize: 200,
                    impressionUrl: "https://test.com",
                    position: 1),
            Contile(id: 2,
                    name: "Mozilla Sponsored Tile",
                    url: "https://mozilla.com",
                    clickUrl: "https://mozilla.com/click",
                    imageUrl: "https://test.com/image2.jpg",
                    imageSize: 200,
                    impressionUrl: "https://example.com",
                    position: 2),
            Contile(id: 3,
                    name: "Focus Sponsored Tile",
                    url: "https://support.mozilla.org/en-US/kb/firefox-focus-ios",
                    clickUrl: "https://support.mozilla.org/en-US/kb/firefox-focus-ios/click",
                    imageUrl: "https://test.com/image3.jpg",
                    imageSize: 200,
                    impressionUrl: "https://another-example.com",
                    position: 3)]
    }

    init(result: ContileResult) {
        self.result = result
    }

    func fetchContiles(timestamp: Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        completion(result)
    }
}
