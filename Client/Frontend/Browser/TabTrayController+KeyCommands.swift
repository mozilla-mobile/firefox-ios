/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

extension TabTrayController {
    override var keyCommands: [UIKeyCommand]? {
        let toggleText = privateMode ? Strings.SwitchToNonPBMKeyCodeTitle: Strings.SwitchToPBMKeyCodeTitle
        return [
            UIKeyCommand(input: "`", modifierFlags: .command, action: #selector(didTogglePrivateModeKeyCommand), discoverabilityTitle: toggleText),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(didCloseTabKeyCommand)),
            UIKeyCommand(input: "\u{8}", modifierFlags: [], action: #selector(didCloseTabKeyCommand), discoverabilityTitle: Strings.CloseTabFromTabTrayKeyCodeTitle),
            UIKeyCommand(input: "w", modifierFlags: [.command, .shift], action: #selector(didCloseAllTabsKeyCommand), discoverabilityTitle: Strings.CloseAllTabsFromTabTrayKeyCodeTitle),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(didEnterTabKeyCommand), discoverabilityTitle: Strings.OpenSelectedTabFromTabTrayKeyCodeTitle),
            UIKeyCommand(input: "\\", modifierFlags: [.command, .shift], action: #selector(didEnterTabKeyCommand)),
            UIKeyCommand(input: "\t", modifierFlags: [.command, .alternate], action: #selector(didEnterTabKeyCommand)),
            UIKeyCommand(input: "t", modifierFlags: .command, action: #selector(didOpenNewTabKeyCommand), discoverabilityTitle: Strings.OpenNewTabFromTabTrayKeyCodeTitle),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
            UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(didChangeSelectedTabKeyCommand(sender:))),
        ]
    }

    @objc func didTogglePrivateModeKeyCommand() {
        // NOTE: We cannot and should not capture telemetry here.
        didTogglePrivateMode()
    }

    @objc func didCloseTabKeyCommand() {
        UnifiedTelemetry.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "close-tab"])
        if let tab = tabManager.selectedTab {
            tabManager.removeTab(tab)
        }
    }

    @objc func didCloseAllTabsKeyCommand() {
        UnifiedTelemetry.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "close-all-tabs"])
        closeTabsForCurrentTray()
    }

    @objc func didEnterTabKeyCommand() {
        UnifiedTelemetry.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "enter-tab"])
        _ = self.navigationController?.popViewController(animated: true)
    }

    @objc func didOpenNewTabKeyCommand() {
        UnifiedTelemetry.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "new-tab"])
        openNewTab()
    }

    @objc func didChangeSelectedTabKeyCommand(sender: UIKeyCommand) {
        UnifiedTelemetry.recordEvent(category: .action, method: .press, object: .keyCommand, extras: ["action": "select-tab"])
        let step: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyInputLeftArrow:
            step = -1
        case UIKeyInputRightArrow:
            step = 1
        case UIKeyInputUpArrow:
            step = -numberOfColumns
        case UIKeyInputDownArrow:
            step = numberOfColumns
        default:
            step = 0
        }

        let tabs = self.tabs
        let currentIndex: Int
        if let selected = tabManager.selectedTab {
            currentIndex = tabs.index(of: selected) ?? 0
        } else {
            currentIndex = 0
        }

        let nextIndex = max(0, min(currentIndex + step, tabs.count - 1))
        let nextTab = tabs[nextIndex]
        tabManager.selectTab(nextTab)
    }
}
