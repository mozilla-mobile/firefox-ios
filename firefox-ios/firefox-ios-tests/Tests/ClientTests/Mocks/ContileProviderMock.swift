// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared

final class ContileProviderMock: ContileProviderInterface, UnifiedAdsProviderInterface, @unchecked Sendable {
    typealias Mock = ContileProviderMock
    private var result: ContileResult

    static var defaultSuccessData: [Contile] {
        return [Contile(id: 1,
                        name: "Firefox",
                        url: "https://firefox.com",
                        clickUrl: "https://firefox.com/click",
                        imageUrl: "https://test.com/image1.jpg",
                        imageSize: 200,
                        impressionUrl: "https://test.com",
                        position: 1),
                Contile(id: 2,
                        name: "Mozilla",
                        url: "https://mozilla.com",
                        clickUrl: "https://mozilla.com/click",
                        imageUrl: "https://test.com/image2.jpg",
                        imageSize: 200,
                        impressionUrl: "https://example.com",
                        position: 2),
                Contile(id: 3,
                        name: "Focus",
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

    func fetchTiles(timestamp: Timestamp, completion: @escaping (UnifiedTileResult) -> Void) {
        switch result {
        case .success(let contiles):
            let unifiedTiles = self.convert(contiles: contiles)
            completion(.success(unifiedTiles))
        case .failure(let error):
            completion(.failure(error))
        }
    }

    func convert(contiles: [Contile]) -> [UnifiedTile] {
        return contiles.enumerated().map { (index, contile) in
            UnifiedTile(format: "tile",
                        url: contile.url,
                        callbacks: UnifiedTileCallback(click: contile.clickUrl, impression: contile.impressionUrl),
                        imageUrl: contile.imageUrl,
                        name: contile.name,
                        blockKey: "Block_key_\(index)")
        }
    }

    static func getContiles(contilesCount: Int,
                            duplicateFirstTile: Bool = false,
                            pinnedDuplicateTile: Bool = false) -> [Contile] {
        var defaultData = ContileProviderMock.defaultSuccessData

        if duplicateFirstTile {
            let duplicateTile = pinnedDuplicateTile ? Mock.pinnedDuplicateTile : Mock.duplicateTile
            defaultData.insert(duplicateTile, at: 0)
        }

        return Array(defaultData.prefix(contilesCount))
    }

    static let pinnedTitle = "A pinned title %@"
    static let pinnedURL = "https://www.apinnedurl.com/pinned%@"
    static let title = "A title %@"
    static let url = "https://www.aurl%@.com"

    static var pinnedDuplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: Mock.pinnedTitle, "0"),
                       url: String(format: Mock.pinnedURL, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageUrl: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }

    static var duplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: Mock.title, "0"),
                       url: String(format: Mock.url, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageUrl: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }
}
