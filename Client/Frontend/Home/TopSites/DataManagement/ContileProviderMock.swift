// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// To be cleaned up once https://github.com/mozilla-mobile/firefox-ios/pull/10182/files is merged
protocol ContileProvider {
    typealias Result = Swift.Result<[Contile], Error>

    func fetchContiles(completion: @escaping (Result) -> Void)
}

struct Contile: Codable {
    let id: Int
    let name: String
    let url: String
    let clickUrl: String
    let imageURL: String
    let imageSize: Int
    let impressionUrl: String
    let position: Int?
}

// TODO: Use in tests only when provider exists
class ContileProviderMock: ContileProvider {

    private var result: ContileProvider.Result

    static var defaultSuccessData: [Contile] {
        return [Contile(id: 1,
                        name: "Firefox",
                        url: "https://firefox.com",
                        clickUrl: "https://firefox.com/click",
                        imageURL: "https://test.com/image1.jpg",
                        imageSize: 200,
                        impressionUrl: "https://test.com",
                        position: 1),
                Contile(id: 2,
                        name: "Mozilla",
                        url: "https://mozilla.com",
                        clickUrl: "https://mozilla.com/click",
                        imageURL: "https://test.com/image2.jpg",
                        imageSize: 200,
                        impressionUrl: "https://example.com",
                        position: 2),
                Contile(id: 3,
                        name: "Focus",
                        url: "https://support.mozilla.org/en-US/kb/firefox-focus-ios",
                        clickUrl: "https://support.mozilla.org/en-US/kb/firefox-focus-ios/click",
                        imageURL: "https://test.com/image3.jpg",
                        imageSize: 200,
                        impressionUrl: "https://another-example.com",
                        position: 3)]
    }

    init(result: ContileProvider.Result = .success([])) {
        self.result = result
    }

    func fetchContiles(completion: @escaping (ContileProvider.Result) -> Void) {
        completion(result)
    }

    enum Error: Swift.Error {
        case invalidData
    }
}
