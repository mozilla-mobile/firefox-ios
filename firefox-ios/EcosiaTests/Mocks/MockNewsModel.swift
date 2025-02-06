// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Ecosia

func createMockNewsModel() throws -> NewsModel? {
    let currentTimestamp = Date().timeIntervalSince1970
    let jsonString = """
    {
        "id": 123,
        "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "language": "en",
        "publishDate": \(currentTimestamp),
        "imageUrl": "https://example.com/image.jpg",
        "targetUrl": "https://example.com/news",
        "trackingName": "example_news_tracking"
    }
    """
    let jsonData = Data(jsonString.utf8)
    let decoder = JSONDecoder()

    // Custom date decoding strategy if needed
    decoder.dateDecodingStrategy = .secondsSince1970
    return try decoder.decode(NewsModel.self, from: jsonData)
}
