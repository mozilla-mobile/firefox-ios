/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol ShortcutsPersister {
    func save(shortcuts: [Shortcut])
    func load() -> [Shortcut]
}

extension UserDefaults: ShortcutsPersister {
    public func save(shortcuts: [Shortcut]) {
        if let encoded = try? JSONEncoder().encode(shortcuts) {
            set(encoded, forKey: "Shortcuts")
        }
    }

    public func load() -> [Shortcut] {
        if let storedObjItem = object(forKey: "Shortcuts") {
            do {
                let decodedShortcuts = try JSONDecoder().decode([Shortcut].self, from: storedObjItem as! Data)
                print("Retrieved items: \(decodedShortcuts)")
                return decodedShortcuts
            } catch let error {
                print(error)
                return []
            }
        }
        return []
    }
}
