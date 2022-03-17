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

    var shouldSucceed: Bool = true
    private var successData: [Contile]
    private var failureResult = Result.failure(Error.invalidData)
    private var successResult: ContileProvider.Result

    static var mockSuccessData: [Contile] {
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
                        position: 2)]
    }

    init(successData: [Contile] = []) {
        self.successData = successData
        self.successResult = Result.success(successData)
    }

    func fetchContiles(completion: @escaping (ContileProvider.Result) -> Void) {
        completion(shouldSucceed ? successResult : failureResult)
    }

    enum Error: Swift.Error {
        case invalidData
    }
}
