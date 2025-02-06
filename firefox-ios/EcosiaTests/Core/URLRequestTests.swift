// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class URLRequestTests: XCTestCase {

    func testAddLanguageRegionHeader() {
        var request = URLRequest(url: URL(string: "https://www.ecosia.org/search")!)
        request.addLanguageRegionHeader()

        let dashedLanguageAndRegion = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-ecosia-app-language-region"), dashedLanguageAndRegion)
    }
}
