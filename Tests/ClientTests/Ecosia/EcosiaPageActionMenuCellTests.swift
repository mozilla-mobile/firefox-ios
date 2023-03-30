// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class EcosiaPageActionMenuCellTests: XCTestCase {
    
    func testDetermineTableViewCellPositionAtReturnsSoloAsPositionForASignleItemArray() {
        // Arrange
        let actions = [[anyPhotonRowAction(), anyPhotonRowAction()],
                       [anyPhotonRowAction()],
                       [anyPhotonRowAction(), anyPhotonRowAction(), anyPhotonRowAction()]]
        
        let indexPath = IndexPath(row: 1, section: 1)
        let cell = makeSUT(at: indexPath)

        // Act
        let position = cell.determineTableViewCellPositionAt(indexPath, forActions: actions)

        // Assert
        XCTAssertEqual(position, .solo)
    }

    func testDetermineTableViewCellPositionAtReturnsFirstAsPositionForMoreThanAnItemInFirstArray() {
        // Arrange
        let actions = [[anyPhotonRowAction(), anyPhotonRowAction()],
                       [anyPhotonRowAction()]]
        
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = makeSUT(at: indexPath)

        // Act
        let position = cell.determineTableViewCellPositionAt(indexPath, forActions: actions)

        // Assert
        XCTAssertEqual(position, .first)
    }
    
    func testDetermineTableViewCellPositionAtReturnsLastAsPositionForMoreThanAnItemInThirdArray() {
        // Arrange
        let actions = [[anyPhotonRowAction(), anyPhotonRowAction()],
                       [anyPhotonRowAction()],
                       [anyPhotonRowAction(), anyPhotonRowAction(), anyPhotonRowAction()]]
        
        let indexPath = IndexPath(row: 2, section: 2)
        let cell = makeSUT(at: indexPath)

        // Act
        let position = cell.determineTableViewCellPositionAt(indexPath, forActions: actions)

        // Assert
        XCTAssertEqual(position, .last)
    }
    
    func testDetermineTableViewCellPositionAtReturnsMiddleAsPositionForAnItemBetweenFirstAndLastItemInSecondArray() {
        // Arrange
        let actions = [[anyPhotonRowAction(), anyPhotonRowAction()],
                       [anyPhotonRowAction(), anyPhotonRowAction(), anyPhotonRowAction(), anyPhotonRowAction()],
                       [anyPhotonRowAction()]]
        
        let indexPath = IndexPath(row: 2, section: 1)
        let cell = makeSUT(at: indexPath)
        
        // Act
        let position = cell.determineTableViewCellPositionAt(indexPath, forActions: actions)

        // Assert
        XCTAssertEqual(position, .middle)
    }
}

extension EcosiaPageActionMenuCellTests {
    
    // MARK: - Helpers
    
    func makeSUT(at indexPath: IndexPath) -> PageActionMenuCell {
        let tableView = UITableView()
        tableView.register(PageActionMenuCell.self, forCellReuseIdentifier: PageActionMenuCell.UX.cellIdentifier)
        return tableView.dequeueReusableCell(withIdentifier: PageActionMenuCell.UX.cellIdentifier, for: indexPath) as! PageActionMenuCell
    }
    
    private func anyPhotonRowAction() -> PhotonRowActions {
        PhotonRowActions(SingleActionViewModel(title: "any string"))
    }
}
