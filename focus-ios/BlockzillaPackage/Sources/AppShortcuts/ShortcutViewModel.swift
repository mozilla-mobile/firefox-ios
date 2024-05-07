/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public enum ShortcutAction {
    case tapped
    case showRenameAlert
    case remove
    case dismiss
}

public class ShortcutViewModel {
    @Published public var shortcut: Shortcut
    public var onTap: (() -> Void)?
    public var onShowRenameAlert: ((Shortcut) -> Void)?
    public var onRemove: ((ShortcutViewModel) -> Void)?
    public var onDismiss: (() -> Void)?
    public var faviconWithLetter: ((String) -> UIImage?)?

    public init(shortcut: Shortcut) {
        self.shortcut = shortcut
    }

    public func send(action: ShortcutAction) {
        switch action {
        case .tapped: onTap?()
        case .showRenameAlert: onShowRenameAlert?(shortcut)
        case .remove: onRemove?(self)
        case .dismiss: onDismiss?()
        }
    }
}

extension ShortcutViewModel: Equatable {
    public static func == (lhs: ShortcutViewModel, rhs: ShortcutViewModel) -> Bool {
        lhs.shortcut == rhs.shortcut
    }
}
