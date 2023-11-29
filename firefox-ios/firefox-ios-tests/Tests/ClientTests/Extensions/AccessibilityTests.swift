// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class AccessibilityTests: XCTestCase {
    
    let view1: UIView = .build { view in
        view.accessibilityLabel = "view 1"
    }
    let view2: UIView = .build{ view in
        view.accessibilityLabel = "view 2"
        view.accessibilityOrderIndex = 2
    }
    let view3: UIView = .build{ view in
        view.accessibilityLabel = "view 3"
    }
    let view4: UIButton = .build { button in
        button.accessibilityLabel = "view 4"
        button.accessibilityOrderIndex = 4
    }
    
    func testAccessibilityOrder() throws {
        var controller = createControllerWithSubViews(subViews: [view1, view2, view3, view4])
        controller.view.sortAccessibilityByOrderIndex()

        var expectedOrder = [view4, view2, view1, view3]
        XCTAssertEqual(controller.view.accessibilityElements as! [UIView], expectedOrder)
    
        
        controller = createControllerWithSubViews(subViews: [view3, view1, view4, view2])
        expectedOrder = [view4, view2, view3, view1]

        controller.view.sortAccessibilityByOrderIndex()
        XCTAssertEqual(controller.view.accessibilityElements as! [UIView], expectedOrder)
    }
    
    private func createControllerWithSubViews(subViews: [UIView]) -> UIViewController {
        let controller = UIViewController()
        subViews.forEach { sub in
            controller.view.addSubview(sub)
        }
        return controller
    }
}
