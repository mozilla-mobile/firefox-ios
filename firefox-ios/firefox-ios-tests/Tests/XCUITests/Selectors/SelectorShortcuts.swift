// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

extension Selector {
    // For elements with id
    static func anyId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .anyById(id), value: id, description: description, groups: groups)
    }

    static func buttonId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .buttonById(id), value: id, description: description, groups: groups)
    }

    static func staticTextId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .staticTextById(id), value: id, description: description, groups: groups)
    }

    static func textFieldId(_ id: String, description: String, groups: [String] = []) -> Selector {
         Selector(strategy: .textFieldById(id), value: id, description: description, groups: groups)
    }

    // For searching for text (label) instead of the id
    static func staticTextByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(format: "elementType == %d AND label == %@", XCUIElement.ElementType.staticText.rawValue, label)
        return Selector(strategy: .predicate(p), value: label, description: description, groups: groups)
    }

    // For containers
    static func collectionViewIdOrLabel(_ value: String, description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.collectionView.rawValue,
            value,
            value
        )
        return Selector(strategy: .predicate(p), value: value, description: description, groups: groups)
    }

    static func tableIdOrLabel(_ value: String, description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.table.rawValue,
            value,
            value
        )
        return Selector(strategy: .predicate(p), value: value, description: description, groups: groups)
    }

    static func buttonByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(
            format: "elementType == %d AND (label == %@ OR identifier == %@)",
            XCUIElement.ElementType.button.rawValue,
            label,
            label
        )
        return Selector(strategy: .predicate(p), value: label, description: description, groups: groups)
    }

    static func navigationBarId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .predicate(
            NSPredicate(
                format: "elementType == %d AND identifier == %@",
                XCUIElement.ElementType.navigationBar.rawValue,
                id
            )
        ),
        value: id,
        description: description,
        groups: groups
        )
    }

    static func firstTable(description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(format: "elementType == %d", XCUIElement.ElementType.table.rawValue)
        return Selector(strategy: .predicate(p), value: "firstTable", description: description, groups: groups)
    }

    static func imageId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .imageById(id), value: id, description: description, groups: groups)
    }

    static func tableOtherById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .otherInTablesById(id), value: id, description: description, groups: groups)
    }

    static func tableCellById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .tableCellById(id), value: id, description: description, groups: groups)
    }

    static func cellById(_ id: String, description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(format: "elementType == %d AND identifier == %@",
                            XCUIElement.ElementType.cell.rawValue,
                            id)
        return Selector(strategy: .predicate(p), value: id, description: description, groups: groups)
    }

    static func cellByLabel(_ label: String, description: String, groups: [String]) -> Selector {
        let p = NSPredicate(format: "elementType == %d AND label == %@",
                            XCUIElement.ElementType.cell.rawValue,
                            label
        )
        return Selector(strategy: .predicate(p), value: label, description: description, groups: groups)
    }

    static func linkById(_ id: String, description: String, groups: [String] = []) -> Selector {
            Selector(strategy: .linkById(id), value: id, description: description, groups: groups)
    }

    static func imageById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(
            strategy: .predicate(
                NSPredicate(
                    format: "elementType == %d AND identifier == %@",
                    XCUIElement.ElementType.image.rawValue,
                    id
                )
            ),
            value: id,
            description: description,
            groups: groups
        )
    }

    static func staticTextByExactLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        Selector(
            strategy: .predicate(
                NSPredicate(
                    format: "elementType == %d AND label == %@",
                    XCUIElement.ElementType.staticText.rawValue,
                    label
                )
            ),
            value: label,
            description: description,
            groups: groups
        )
    }

    static func staticTextLabelContains(_ text: String, description: String, groups: [String] = []) -> Selector {
        Selector(
            strategy: .predicate(
                NSPredicate(
                    format: "elementType == %d AND label CONTAINS %@",
                    XCUIElement.ElementType.staticText.rawValue,
                    text
                )
            ),
            value: text,
            description: description,
            groups: groups
        )
    }

    static func cellStaticTextLabelContains(_ text: String, description: String, groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND label CONTAINS[c] %@",
            XCUIElement.ElementType.staticText.rawValue,
            text
        )
        return Selector(strategy: .predicate(predicate),
                        value: text,
                        description: description,
                        groups: groups)
    }

    static func searchFieldById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .predicate(
            NSPredicate(format: "elementType == %d AND identifier == %@", XCUIElement.ElementType.searchField.rawValue, id)
            ),
                 value: id,
                 description: description,
                 groups: groups
        )
    }

    static func linkStaticTextByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND label == %@",
            XCUIElement.ElementType.staticText.rawValue,
            label
        )
        return Selector(strategy: .predicate(predicate),
                        value: label,
                        description: description,
                        groups: groups
        )
    }

    static func switchById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .predicate(
            NSPredicate(format: "elementType == %d AND identifier == %@",
                        XCUIElement.ElementType.switch.rawValue,
                        id)
            ),
                 value: id,
                 description: description,
                 groups: groups
        )
    }
}
