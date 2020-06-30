/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Storage
import Shared
import XCTest

class LoginsListViewModelTests: XCTestCase {
    var viewModel: LoginListViewModel?

    override func setUp() {
        let profile = MockProfile()
        let searchController = UISearchController()

        self.viewModel = LoginListViewModel(profile: profile, searchController: searchController)
    }

//    func testLoadLogins() {
//
//    }
    
    func testQueryLogins() {
        
    }

    func testIsDuringSearchControllerDismiss() {
        
    }

    func testLoginAtIndexPath() {
        
    }

    func testLoginsForSection() {

    }

    func testSetLogins() {
        
    }

}

class LoginsListSelectionHelperTests: XCTestCase {
    func testSelectIndexPath() {

    }

    func testIdexPathIsSelected() {

    }

    func testDeselectIndexPathh() {

    }

    func testDeselectAll() {

    }

    func testSelectIndexPaths() {

    }
}

class LoginsListDataSourceTests: XCTestCase {

    func testNumberOfSections() {

    }

    func testNumberOfRowsInSection() {

    }

    func testCellForRowAt() {

    }
}
