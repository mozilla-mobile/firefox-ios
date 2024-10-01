// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class DefaultFolderHeirarchyFetcherTests: XCTestCase {
    var mockProfile: MockProfile!
    let rootFolderGUID = "mobile___"

    override func setUp() {
        mockProfile = MockProfile()
        super.setUp()
    }
    
    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }
    
    func testFolder() {
        let subject = createSubject()
        
    }
    
    private func createSubject() -> DefaultFolderHierarchyFetcher {
        let subject = DefaultFolderHierarchyFetcher(profile: mockProfile, rootFolderGUID: rootFolderGUID)
        return subject
    }
}
