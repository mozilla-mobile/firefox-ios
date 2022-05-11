/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public protocol ShortcutsManagerDelegate: AnyObject {
    func shortcutsDidUpdate()
    func shortcutDidUpdate(shortcut: Shortcut)
}

public class ShortcutsManager {
    let shortcutsKey = "Shortcuts"

    public private(set) var shortcuts: [Shortcut] {
        didSet {
            persister.save(shortcuts: shortcuts)
        }
    }

    public weak var delegate: ShortcutsManagerDelegate?

    private let persister: ShortcutsPersister

    public init(persister: ShortcutsPersister = UserDefaults.standard) {
        self.persister = persister
        self.shortcuts = persister.load()
    }

    private func canSave(shortcut: Shortcut) -> Bool {
        shortcuts.count < Self.maximumNumberOfShortcuts && !isSaved(shortcut: shortcut)
    }
}

public extension ShortcutsManager {
    func add(shortcut: Shortcut) {
        if canSave(shortcut: shortcut) {
            shortcuts.append(shortcut)
            delegate?.shortcutsDidUpdate()
        }
    }

    func remove(shortcut: Shortcut) {
        if let index = shortcuts.firstIndex(of: shortcut) {
            shortcuts.remove(at: index)
            delegate?.shortcutsDidUpdate()
        }
    }

    func rename(shortcut: Shortcut, newName: String) {
        var renamedShortcut = shortcut
        renamedShortcut.name = newName
        if let index = shortcuts.firstIndex(of: shortcut), renamedShortcut.name != shortcuts[index].name {
            shortcuts[index] = renamedShortcut
            delegate?.shortcutDidUpdate(shortcut: shortcuts[index])
        }
    }

    func isSaved(shortcut: Shortcut) -> Bool {
        shortcuts.contains(shortcut) ? true : false
    }
}

public extension ShortcutsManager {
    static let maximumNumberOfShortcuts = 4
}
