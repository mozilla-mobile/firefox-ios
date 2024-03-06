/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIHelpers
import UIKit

public class ShortcutsManager {
    let shortcutsKey = "Shortcuts"

    private var shortcuts: [Shortcut] {
        shortcutsViewModels.map(\.shortcut)
    }
    private let persister: ShortcutsPersister

    public private(set) var shortcutsViewModels: [ShortcutViewModel] = []
    public var onTap: ((URL) -> Void)?
    public var onShowRenameAlert: ((Shortcut) -> Void)?
    public var onRemove: (() -> Void)?
    public var onDismiss: (() -> Void)?
    public var shortcutsDidUpdate: (() -> Void)?
    public var shortcutDidRemove: ((ShortcutViewModel) -> Void)?
    public var faviconWithLetter: (String) -> UIImage? = { letter in
        FaviIconGenerator
            .shared
            .faviconImage(
                capitalLetter: letter,
                textColor: .primaryText,
                backgroundColor: .foundation
            )
    }

    public var hasSpace: Bool {
        shortcutsViewModels.count < ShortcutsManager.maximumNumberOfShortcuts
    }

    public init(persister: ShortcutsPersister = UserDefaults.standard) {
        self.persister = persister
        let shortcuts = persister.load()
        for shortcut in shortcuts {
            bind(shortcutViewModel: .init(shortcut: shortcut))
        }
    }

    private func bind(shortcutViewModel: ShortcutViewModel) {
        shortcutViewModel.onTap = { [weak self] in
            self?.onTap?(shortcutViewModel.shortcut.url)
        }

        shortcutViewModel.onShowRenameAlert = { [weak self] shortcut in
            self?.onShowRenameAlert?(shortcut)
        }

        shortcutViewModel.onRemove = { [weak self] viewModel in
            self?.remove(viewModel)
            self?.onRemove?()
        }

        shortcutViewModel.onDismiss = { [weak self] in
            self?.onDismiss?()
        }

        shortcutViewModel.faviconWithLetter = faviconWithLetter
        shortcutsViewModels.append(shortcutViewModel)
    }

    private func canSave(shortcut: Shortcut) -> Bool {
        hasSpace && !isSaved(url: shortcut.url)
    }

    private func saveShortcuts() {
        persister.save(shortcuts: shortcuts)
    }
}

public extension ShortcutsManager {
    func add(shortcutViewModel: ShortcutViewModel) {
        if canSave(shortcut: shortcutViewModel.shortcut) {
            bind(shortcutViewModel: shortcutViewModel)
            saveShortcuts()
            shortcutsDidUpdate?()
        }
    }

    func remove(_ shortcutViewModel: ShortcutViewModel) {
        if let index = shortcutsViewModels.firstIndex(of: shortcutViewModel) {
            shortcutsViewModels.remove(at: index)
            saveShortcuts()
            shortcutDidRemove?(shortcutViewModel)
        }
    }

    func remove(_ url: URL) {
        if let index = shortcutsViewModels.firstIndex(where: { $0.shortcut.url == url }) {
            let shortcutViewModel = shortcutsViewModels.remove(at: index)
            saveShortcuts()
            shortcutDidRemove?(shortcutViewModel)
        }
    }

    func rename(shortcut: Shortcut, newName: String) {
        if let index = shortcutsViewModels.firstIndex(where: { $0.shortcut == shortcut && $0.shortcut.name != newName }) {
            shortcutsViewModels[index].shortcut.name = newName
            saveShortcuts()
        }
    }

    func isSaved(url: URL) -> Bool {
        shortcutsViewModels.contains(where: { $0.shortcut.url == url })
    }

    func update(faviconURL: URL, for url: URL) {
        guard let index = shortcutsViewModels.firstIndex(where: { $0.shortcut.url == url }) else { return }
        guard faviconURL != shortcutsViewModels[index].shortcut.imageURL else { return }
        shortcutsViewModels[index].shortcut.imageURL = faviconURL
        saveShortcuts()
        shortcutsDidUpdate?()
    }
}

public extension ShortcutsManager {
    static let maximumNumberOfShortcuts = 4
}
