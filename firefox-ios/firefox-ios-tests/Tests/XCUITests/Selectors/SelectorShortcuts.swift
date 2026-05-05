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

    static func webViewOtherByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.other.rawValue,
            label,
            label
        )
        return Selector(strategy: .predicate(predicate),
                        value: label,
                        description: description,
                        groups: groups)
    }

    static func navigationBarByTitle(_ title: String, description: String, groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.navigationBar.rawValue,
            title,
            title
        )
        return Selector(strategy: .predicate(predicate),
                        value: title,
                        description: description,
                        groups: groups)
    }

    static func tableCellByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (label == %@ OR identifier == %@)",
            XCUIElement.ElementType.cell.rawValue,
            label,
            label
        )
        return Selector(strategy: .predicate(predicate),
                        value: label,
                        description: description,
                        groups: groups)
    }

    static func buttonIdOrLabel(_ value: String,
                                description: String,
                                groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.button.rawValue,
            value,
            value
        )
        return Selector(strategy: .predicate(predicate),
                        value: value,
                        description: description,
                        groups: groups
        )
    }

    static func springboardPasscodeField(description: String, groups: [String] = []) -> Selector {
        let p = NSPredicate(
            format: "elementType == %d",
            XCUIElement.ElementType.secureTextField.rawValue
        )
        return Selector(strategy: .predicate(p),
                        value: "springboardPasscode",
                        description: description,
                        groups: groups
        )
    }

    static func switchByIdOrLabel(_ value: String,
                                  description: String,
                                  groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (identifier == %@ OR label == %@)",
            XCUIElement.ElementType.switch.rawValue,
            value,
            value
        )
        return Selector(strategy: .predicate(predicate),
                        value: value,
                        description: description,
                        groups: groups)
    }

    static func buttonLabelContains(_ text: String,
                                    description: String,
                                    groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND label CONTAINS[c] %@",
            XCUIElement.ElementType.button.rawValue,
            text
        )

        return Selector(
            strategy: .predicate(predicate),
            value: text,
            description: description,
            groups: groups
        )
    }

    static func anyIdOrLabel(_ value: String,
                             description: String,
                             groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "(identifier == %@ OR label == %@)",
            value,
            value
        )

        return Selector(
            strategy: .predicate(predicate),
            value: value,
            description: description,
            groups: groups
        )
    }

    static func alertByTitle(_ title: String,
                             description: String,
                             groups: [String] = []) -> Selector {
        let predicate = NSPredicate(
            format: "elementType == %d AND (identifier CONTAINS[c] %@ OR label CONTAINS[c] %@)",
            XCUIElement.ElementType.alert.rawValue,
            title,
            title
        )

        return Selector(
            strategy: .predicate(predicate),
            value: title,
            description: description,
            groups: groups
        )
    }

    static func tableFirstMatch(description: String,
                                groups: [String] = []) -> Selector {
            Selector(strategy: .anyById(""),
                     value: "FirstTable",
                     description: description,
                     groups: groups)
    }

    static func tableById(_ value: String,
                          description: String,
                          groups: [String] = []) -> Selector {
        Selector(strategy: .tableById(value),
                 value: value,
                 description: description,
                 groups: groups)
    }

    static func staticTextInTablesByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
          Selector(
              strategy: .staticTextInTablesByLabel(label),
              value: label,
              description: description,
              groups: groups
          )
      }

    static func tableCellButtonById(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .tableCellButtonById(id), value: id, description: description, groups: groups)
    }

    static func navigationBarByIdOrLabel(_ value: String, description: String, groups: [String] = []) -> Selector {
        Selector(
            strategy: .navigationBarByIdOrLabel(value),
            value: value,
            description: description,
            groups: groups
        )
     }

    static func linkStaticTextById(_ id: String, description: String, groups: [String] = []) -> Selector {
          Selector(
              strategy: .linkStaticTextById(id),
              value: id,
              description: description,
              groups: groups
          )
    }

    static func pageIndicatorById(_ id: String, description: String, groups: [String] = []) -> Selector {
         return Selector(strategy: .pageIndicatorById(id), value: id, description: description, groups: groups)
    }

    static func buttonStaticTextByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
          Selector(
              strategy: .buttonStaticTextByLabel(label),
              value: label,
              description: description,
              groups: groups
          )
    }

    static func otherElementsButtonStaticTextByLabel(
        _ label: String,
        description: String,
        groups: [String] = []) -> Selector {
          Selector(
              strategy: .otherElementsButtonStaticTextByLabel(label),
              value: label,
              description: description,
              groups: groups
          )
    }

    static func collectionViewLinkById(_ id: String, description: String, groups: [String] = []) -> Selector {
          Selector(
              strategy: .collectionViewLinkById(id),
              value: id,
              description: description,
              groups: groups
          )
    }

    static func cellButtonById(_ id: String, description: String, groups: [String] = []) -> Selector {
          Selector(
              strategy: .cellButtonById(id),
              value: id,
              description: description,
              groups: groups
          )
    }

    static func otherElementId(_ id: String, description: String, groups: [String] = []) -> Selector {
          Selector(strategy: .predicate(
              NSPredicate(
                  format: "elementType == %d AND identifier == %@",
                  XCUIElement.ElementType.other.rawValue,
                  id
              )
          ),
          value: id,
          description: description,
          groups: groups
          )
    }

    static func otherElementByLabel(_ label: String, description: String, groups: [String] = []) -> Selector {
          Selector(strategy: .predicate(
              NSPredicate(
                  format: "elementType == %d AND label == %@",
                  XCUIElement.ElementType.other.rawValue,
                  label
              )
          ),
          value: label,
          description: description,
          groups: groups
          )
    }
}

extension XCUIElement {
    func buttonContainingText(_ text: String) -> XCUIElement {
        return self.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
}
