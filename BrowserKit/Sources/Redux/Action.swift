// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Used to describe an action that can be dispatched by the redux store
public protocol Action: Sendable, CustomDebugStringConvertible {
    var windowUUID: WindowUUID { get }
    var actionType: ActionType { get }
}

extension Action {
    func displayString() -> String {
        let className = String(describing: Self.self)
        return "\(className) \(actionType)"
    }

    public var debugDescription: String {
        let className = String(describing: type(of: self))
        return "<\(className)> Type: \(actionType) Window: \(windowUUID.uuidString.prefix(4))"
    }
}

public protocol ActionType: Sendable {}

/// Used to describe an action that can be dispatched by the redux store.
/// `ModernAction` is the replacement for the old `Action` and `ActionType` protocols, which will be deprecated
/// in the future.
public protocol ModernAction: Sendable {
    var description: String { get }
}

extension ModernAction {
    /// Automatically generates a debug description for enumerated actions with nested associated values.
    var description: String {
        let mirror = Mirror(reflecting: self)
        let enumTypeName = "\(mirror.subjectType)"

        guard let caseName = mirror.children.first?.label,
              let associatedValue = mirror.children.first?.value else {
            // Enum without an associated value
            return "\(enumTypeName).\(self)"
        }

        // Print the associated value(s) if possible
        let associatedValueMirror = Mirror(reflecting: associatedValue)
        if associatedValueMirror.children.isEmpty {
            // Also enum without an associated value
            return "\(enumTypeName).\(caseName)"
        }

        // Pretty print the Action's payload, one item per line, in curly brackets
        let indentValue = "\n   "
        let numberOfChildren = associatedValueMirror.children.count
        let values = indentValue + associatedValueMirror.children.enumerated().map { index, child in
            let label = child.label ?? ""
            let value = child.value
            let optionalTrailingComma = index < (numberOfChildren - 1) ? "," : ""
            return label.isEmpty
                   ? "\(value)"
                   : "\(label): \(value)\(optionalTrailingComma)"
        }.joined(separator: indentValue)

//        let optionalTrailingComma = numberOfChildren > 1 ? "," : ""

        return "\(enumTypeName).\(caseName) {\(values)\n}"
    }
}
