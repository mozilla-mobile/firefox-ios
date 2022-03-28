// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit

extension GridTabViewController {
    override var keyCommands: [UIKeyCommand]? {
        let toggleText: String = tabDisplayManager.isPrivate ? .KeyboardShortcuts.NormalBrowsingMode: .KeyboardShortcuts.PrivateBrowsingMode
        let commands = [
            UIKeyCommand(action: #selector(didTogglePrivateModeKeyCommand), input: "`", modifierFlags: .command,  discoverabilityTitle: toggleText),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(didCloseTabKeyCommand)),
            
            UIKeyCommand(action: #selector(didCloseAllTabsKeyCommand), input: "w", modifierFlags: [.command, .shift],  discoverabilityTitle: .KeyboardShortcuts.CloseAllTabsInTabTray),
            UIKeyCommand(input: "\\", modifierFlags: [.command, .shift], action: #selector(didEnterTabKeyCommand)),
            UIKeyCommand(input: "\t", modifierFlags: [.command, .alternate], action: #selector(didEnterTabKeyCommand)),
            UIKeyCommand(action: #selector(didOpenNewTabKeyCommand), input: "t", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.OpenNewTabInTabTray),
        ]

        let arrowKeysCommands = [
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
        ]

        // In iOS 15+, certain keys events are delivered to the text input or focus systems first, unless specified otherwise
        if #available(iOS 15, *) {
            arrowKeysCommands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }

        return commands + arrowKeysCommands
    }

    @objc func didTogglePrivateModeKeyCommand() {
        // NOTE: We cannot and should not capture telemetry here.
        didTogglePrivateMode()
    }

    @objc func didCloseTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "close-tab"])
        if let tab = tabManager.selectedTab {
            tabManager.removeTab(tab)
        }
    }

    @objc func didCloseAllTabsKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "close-all-tabs"])
        closeTabsForCurrentTray()
    }

    @objc func didEnterTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "enter-tab"])
        dismissVC()
    }

    @objc func didOpenNewTabKeyCommand() {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "new-tab"])
        openNewTab(isPrivate: tabDisplayManager.isPrivate)
    }

    @objc func didChangeSelectedTabKeyCommand(sender: UIKeyCommand) {
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "select-tab"])
        let step: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyCommand.inputLeftArrow:
            step = -1
        case UIKeyCommand.inputRightArrow:
            step = 1
        case UIKeyCommand.inputUpArrow:
            step = -numberOfColumns
        case UIKeyCommand.inputDownArrow:
            step = numberOfColumns
        default:
            step = 0
        }

        let tabs = tabDisplayManager.dataStore
        let currentIndex: Int
        if let selected = tabManager.selectedTab {
            currentIndex = tabs.index(of: selected) ?? 0
        } else {
            currentIndex = 0
        }

        let nextIndex = max(0, min(currentIndex + step, tabs.count - 1))
        if let nextTab = tabs.at(nextIndex) {
            tabManager.selectTab(nextTab)
        }
    }
}
