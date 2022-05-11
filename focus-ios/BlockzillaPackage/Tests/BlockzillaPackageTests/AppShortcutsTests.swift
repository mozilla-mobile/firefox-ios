/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import AppShortcuts

class MockShortcutDelegate: ShortcutsManagerDelegate {
    var shortcutsDidUpdateTrigger = false
    var updatedShortcut: Shortcut?

    func shortcutsDidUpdate() {
        shortcutsDidUpdateTrigger = true
    }

    func shortcutDidUpdate(shortcut: Shortcut) {
        updatedShortcut = shortcut
    }
}

class MockPersister: ShortcutsPersister {
    func save(shortcuts: [Shortcut]) {

    }

    func load() -> [Shortcut] {
        return []
    }
}

class AppShortcutsTests: XCTestCase {

    var sut: ShortcutsManager!

    override func setUp() {
        sut = ShortcutsManager(persister: MockPersister())
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "Shortcuts")
        sut = nil
    }

    func testAddingShortcutIsAddedToShortcutsList() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        sut.add(shortcut: shortcut)

        // Then
        XCTAssertEqual(sut.shortcuts.count, 1)
    }

    func testAddingTheSameShortcutWillNotShowTwice() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        sut.add(shortcut: shortcut)
        sut.add(shortcut: shortcut)

        // Then
        XCTAssertEqual(sut.shortcuts.count, 1)
    }

    func testAddingShortcutTriggersShortcutsDidUpdate() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)
        let delegate = MockShortcutDelegate()
        sut.delegate = delegate

        // When
        sut.add(shortcut: shortcut)

        // Then
        XCTAssertEqual(sut.shortcuts.count, 1)
        XCTAssertTrue(delegate.shortcutsDidUpdateTrigger)
    }

    func testRenamingShortcutTriggersShortcutViewUpdate() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)
        let delegate = MockShortcutDelegate()
        sut.delegate = delegate

        // When
        sut.add(shortcut: shortcut)
        sut.rename(shortcut: shortcut, newName: "TestGoogle")

        // Then
        XCTAssertEqual(sut.shortcuts.count, 1)
        XCTAssertEqual(delegate.updatedShortcut?.name, "TestGoogle")
    }

    func testAddingFiveShortcutsAddsOnlyTheFirstFour() {
        // Given
        let shortcut1 = Shortcut(url: URL(string: "https://www.google.com")!)
        let shortcut2 = Shortcut(url: URL(string: "https://www.facebook.com")!)
        let shortcut3 = Shortcut(url: URL(string: "https://www.reddit.com")!)
        let shortcut4 = Shortcut(url: URL(string: "https://www.twitter.com")!)

        let shortcut5 = Shortcut(url: URL(string: "https://www.dribble.com")!)

        // When
        sut.add(shortcut: shortcut1)
        sut.add(shortcut: shortcut2)
        sut.add(shortcut: shortcut3)
        sut.add(shortcut: shortcut4)
        sut.add(shortcut: shortcut5)

        // Then
        XCTAssertEqual(sut.shortcuts, [shortcut1, shortcut2, shortcut3, shortcut4])
    }
}
