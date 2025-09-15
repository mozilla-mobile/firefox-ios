// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

enum SelectorStrategy {
    case buttonById(String)
    case staticTextById(String)
    case anyById(String)                 // button or label
    case staticTextLabelContains(String) // text that contains a fragment
    case predicate(NSPredicate)          // escape hatch
}

// Selector model (with metadata)
struct Selector {
    let strategy: SelectorStrategy
    let value: String
    let description: String
    let groups: [String]

    init(strategy: SelectorStrategy,
         value: String,
         description: String,
         groups: [String] = []) {
        self.strategy = strategy
        self.value = value
        self.description = description
        self.groups = groups
    }
}

// Resolver
extension Selector {
    // Return an element from the selector.
    func element(in app: XCUIApplication) -> XCUIElement {
        switch strategy {
        case .buttonById:
            return app.buttons[value]
        case .staticTextById:
            return app.staticTexts[value]
        case .anyById:
            // First the button, otherwise the staticText
            let button = app.buttons[value]
            if button.exists { return button }
            return app.staticTexts[value]
        case .staticTextLabelContains:
            return app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", value)).element(boundBy: 0)
        case .predicate(let p):
            return app.descendants(matching: .any).matching(p).element(boundBy: 0)
        }
    }

    func query(in app: XCUIApplication) -> XCUIElementQuery {
        switch strategy {
        case .buttonById:
            return app.buttons.matching(identifier: value)
        case .staticTextById:
            return app.staticTexts.matching(identifier: value)
        case .anyById:
            // Return the .any with the identifier to use exists/firstMatch
            let pred = NSPredicate(format: "identifier == %@", value)
            return app.descendants(matching: .any).matching(pred)
        case .staticTextLabelContains:
            let pred = NSPredicate(format: "label CONTAINS %@", value)
            return app.staticTexts.containing(pred)
        case .predicate(let p):
            return app.descendants(matching: .any).matching(p)
        }
    }
}
