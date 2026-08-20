// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol MarkupSelectorsSet {
    var PALETTE: Selector { get }
    var PEN_TOOL: Selector { get }
    var QUICK_LOOK_MARKUP_TOGGLE: Selector { get }
    var MARKUP_BUTTON: Selector { get }
    var MARKUP_SWITCH: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

// QuickLook and PencilKit internals, matched the way the share sheet exposes them.
struct MarkupSelectors: MarkupSelectorsSet {
    let PALETTE = Selector.otherElementId(
        "Drawing-Palette",
        description: "The PencilKit drawing palette shown once markup is open",
        groups: ["markup"]
    )

    let PEN_TOOL = Selector.buttonIdOrLabel(
        "Pen",
        description: "The pen tool in the PencilKit drawing palette",
        groups: ["markup"]
    )

    let QUICK_LOOK_MARKUP_TOGGLE = Selector.switchById(
        "QLOverlayMarkupButtonAccessibilityIdentifier",
        description: "The QuickLook overlay control that switches the preview into markup mode",
        groups: ["markup"]
    )

    let MARKUP_BUTTON = Selector.buttonIdOrLabel(
        "Markup",
        description: "The Markup control exposed as a button",
        groups: ["markup"]
    )

    let MARKUP_SWITCH = Selector.switchByIdOrLabel(
        "Markup",
        description: "The Markup control exposed as a switch",
        groups: ["markup"]
    )

    let CLOSE_BUTTON = Selector.buttonIdOrLabel(
        "close",
        description: "The button that dismisses the markup tool",
        groups: ["markup"]
    )

    var all: [Selector] {
        return [PALETTE, PEN_TOOL, QUICK_LOOK_MARKUP_TOGGLE, MARKUP_BUTTON, MARKUP_SWITCH, CLOSE_BUTTON]
    }
}
