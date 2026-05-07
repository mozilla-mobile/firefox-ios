// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Controls how chip titles are rendered. Prefer `.configuration` unless text
/// visually disturbs system-provided backdrops, such as in pinned collection view headers.
public enum ChipButtonTitleRendering {
    case configuration
    case coreAnimationLayer
}

public struct ChipButtonViewModel {
    public let title: String
    public let a11yIdentifier: String?
    public let isSelected: Bool
    public let titleRendering: ChipButtonTitleRendering
    public var tappedAction: (@MainActor (UIButton) -> Void)?

    public init(
        title: String,
        a11yIdentifier: String,
        isSelected: Bool,
        titleRendering: ChipButtonTitleRendering = .configuration,
        touchUpAction: (@MainActor (UIButton) -> Void)?
    ) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.isSelected = isSelected
        self.titleRendering = titleRendering
        self.tappedAction = touchUpAction
    }
}
