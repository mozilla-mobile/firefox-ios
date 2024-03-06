/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import AppShortcuts

class MockPersister: ShortcutsPersister {
    var savedShortcuts: [Shortcut] = []

    init(savedShortcuts: [Shortcut] = []) {
        self.savedShortcuts = savedShortcuts
    }

    func save(shortcuts: [Shortcut]) {
        savedShortcuts = shortcuts
    }

    func load() -> [Shortcut] {
        return savedShortcuts
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
        sut.add(shortcutViewModel: .init(shortcut: shortcut))

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
    }

    func testAddingTheSameShortcutWillNotShowTwice() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        sut.add(shortcutViewModel: .init(shortcut: shortcut))
        sut.add(shortcutViewModel: .init(shortcut: shortcut))

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
    }

    func testAddingShortcutTriggersShortcutsDidUpdate() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        var shortcutsDidUpdateTrigger = false
        sut.shortcutsDidUpdate = {
            shortcutsDidUpdateTrigger = true
        }
        let viewModel = ShortcutViewModel(shortcut: shortcut)
        sut.add(shortcutViewModel: viewModel)

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
        XCTAssertTrue(shortcutsDidUpdateTrigger)
    }

    func testRenamingShortcutTriggersAlertAction() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        let viewModel = ShortcutViewModel(shortcut: shortcut)
        sut.add(shortcutViewModel: viewModel)

        var expectedShortcut: Shortcut?
        sut.onShowRenameAlert = { expectedShortcut = $0 }
        viewModel.send(action: .showRenameAlert)

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
        XCTAssertEqual(shortcut, expectedShortcut)
    }

    func testTappingShortcutTriggersTapAction() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        let viewModel = ShortcutViewModel(shortcut: shortcut)
        sut.add(shortcutViewModel: viewModel)

        var tappedURL: URL?
        sut.onTap = { url in
            tappedURL = url
        }
        viewModel.send(action: .tapped)

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
        XCTAssertEqual(shortcut.url, tappedURL)
    }

    func testRemovingShortcutTriggersRemoveAction() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        let viewModel = ShortcutViewModel(shortcut: shortcut)
        sut.add(shortcutViewModel: viewModel)

        var removeTapped = false
        sut.onRemove = { removeTapped = true }
        viewModel.send(action: .remove)

        // Then
        XCTAssertTrue(sut.shortcutsViewModels.isEmpty)
        XCTAssertTrue(removeTapped)
    }

    func testDismissContentMenuTriggersDismissAction() {
        // Given
        let shortcut = Shortcut(url: URL(string: "https://www.google.com")!)

        // When
        let viewModel = ShortcutViewModel(shortcut: shortcut)
        sut.add(shortcutViewModel: viewModel)

        var dismissTapped = false
        sut.onDismiss = { dismissTapped = true }
        viewModel.send(action: .dismiss)

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.count, 1)
        XCTAssertTrue(dismissTapped)
    }

    func testAddingFiveShortcutsAddsOnlyTheFirstFour() {
        // Given
        let shortcut1 = Shortcut(url: URL(string: "https://www.google.com")!)
        let shortcut2 = Shortcut(url: URL(string: "https://www.facebook.com")!)
        let shortcut3 = Shortcut(url: URL(string: "https://www.reddit.com")!)
        let shortcut4 = Shortcut(url: URL(string: "https://www.twitter.com")!)

        let shortcut5 = Shortcut(url: URL(string: "https://www.dribble.com")!)

        // When
        sut.add(shortcutViewModel: .init(shortcut: shortcut1))
        sut.add(shortcutViewModel: .init(shortcut: shortcut2))
        sut.add(shortcutViewModel: .init(shortcut: shortcut3))
        sut.add(shortcutViewModel: .init(shortcut: shortcut4))
        sut.add(shortcutViewModel: .init(shortcut: shortcut5))

        // Then
        XCTAssertEqual(sut.shortcutsViewModels.map(\.shortcut), [shortcut1, shortcut2, shortcut3, shortcut4])
    }
}
