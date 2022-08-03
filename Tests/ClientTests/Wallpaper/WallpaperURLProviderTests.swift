// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperURLProviderTests: XCTestCase {

    let testURL = WallpaperURLProvider.testURL

    func testMetadataURL() {
        let sut = WallpaperURLProvider()
        let expectedURL = URL(string: "\(testURL)/metadata/\(sut.currentMetadataEndpoint)/wallpapers.json")

        do {
            let actualURL = try sut.url(for: .metadata)
            XCTAssertEqual(actualURL,
                           expectedURL,
                           "The metadata url builder is returning the wrong url.")

        } catch {
            XCTFail("The url provider failed to provide any url: \(error.localizedDescription)")
        }
    }

    func testPathURL() {
        let sut = WallpaperURLProvider()
        let path = "path/to/image"
        let expectedURL = URL(string: "\(testURL)/\(path).png")

        do {
            let actualURL = try sut.url(for: .imageURL, withComponent: path)
            XCTAssertEqual(actualURL,
                           expectedURL,
                           "The image url builder is returning the wrong url.")

        } catch {
            XCTFail("The url provider failed to provide any url: \(error.localizedDescription)")
        }
    }
}
