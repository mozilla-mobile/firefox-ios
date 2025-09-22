// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ZoomBarSelectorsSet {
    var ZOOM_IN_BUTTON: Selector { get }
    var ZOOM_OUT_BUTTON: Selector { get }
    var ZOOM_LEVEL_ANY: Selector { get }       // Label of % (sometimes is a button, sometimes a staticText)
    var BOOK_OF_MOZILLA_TEXT: Selector { get } // Visual verification of a text
    var all: [Selector] { get }                // health checks, if needed
}

struct ZoomBarSelectors: ZoomBarSelectorsSet {
    private enum IDs {
        static let zoomIn  = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton
        static let zoomOut = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton
        static let zoomPct = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel
    }

    let ZOOM_IN_BUTTON = Selector(
        strategy: .buttonById(IDs.zoomIn),
        value: IDs.zoomIn,
        description: "Zoom In + button",
        groups: ["requiredForPage", "zoom"]
    )

    let ZOOM_OUT_BUTTON = Selector(
        strategy: .buttonById(IDs.zoomOut),
        value: IDs.zoomOut,
        description: "Zoom Out - button",
        groups: ["requiredForPage", "zoom"]
    )

    let ZOOM_LEVEL_ANY = Selector(
        strategy: .anyById(IDs.zoomPct),
        value: IDs.zoomPct,
        description: "Zoom percentage label/button",
        groups: ["requiredForPage", "zoom"]
    )

    let BOOK_OF_MOZILLA_TEXT = Selector(
        strategy: .staticTextLabelContains("The Book of Mozilla"),
        value: "The Book of Mozilla",
        description: "Content text used to validate visual size change",
        groups: ["visualCheck"]
    )

    var all: [Selector] { [ZOOM_IN_BUTTON, ZOOM_OUT_BUTTON, ZOOM_LEVEL_ANY, BOOK_OF_MOZILLA_TEXT] }
}

// Experimental
struct ExperimentalZoomBarSelectors: ZoomBarSelectorsSet {
    private let base = ZoomBarSelectors()

    // If the selectors aren’t changing for the experiment, let’s inherit them from the default.
    var ZOOM_IN_BUTTON: Selector { base.ZOOM_IN_BUTTON }
    var ZOOM_OUT_BUTTON: Selector { base.ZOOM_OUT_BUTTON }
    var ZOOM_LEVEL_ANY: Selector { base.ZOOM_LEVEL_ANY }
    var BOOK_OF_MOZILLA_TEXT: Selector { base.BOOK_OF_MOZILLA_TEXT }

    var all: [Selector] { [ZOOM_IN_BUTTON, ZOOM_OUT_BUTTON, ZOOM_LEVEL_ANY, BOOK_OF_MOZILLA_TEXT] }
}
