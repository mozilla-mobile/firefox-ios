/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreGraphics

class BrowserToolset {
    weak var delegate: BrowserToolsetDelegate?

    lazy var backButton: InsetButton = {
        let backButton = InsetButton()
        backButton.setImage(.backActive, for: .normal)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        backButton.accessibilityLabel = UIConstants.strings.browserBack
        backButton.isEnabled = false
        return backButton
    }()

    lazy var forwardButton: InsetButton = {
        let forwardButton = InsetButton()
        forwardButton.setImage(.forwardActive, for: .normal)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        forwardButton.accessibilityLabel = UIConstants.strings.browserForward
        forwardButton.isEnabled = false
        return forwardButton
    }()

    lazy var stopReloadButton: InsetButton = {
        let stopReloadButton = InsetButton()
        stopReloadButton.setImage(.refreshMenu, for: .normal)
        stopReloadButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stopReloadButton.accessibilityIdentifier = "BrowserToolset.stopReloadButton"
        return stopReloadButton
    }()

    lazy var deleteButton: InsetButton = {
        let deleteButton = InsetButton()
        deleteButton.setImage(.delete, for: .normal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        deleteButton.isEnabled = false
        return deleteButton
    }()

    lazy var contextMenuButton: InsetButton = {
        let contextMenuButton = InsetButton()
        contextMenuButton.setImage(.hamburgerMenu, for: .normal)
        contextMenuButton.tintColor = .primaryText
        if #available(iOS 14.0, *) {
            contextMenuButton.showsMenuAsPrimaryAction = true
            contextMenuButton.menu = UIMenu(children: [])
            contextMenuButton.addTarget(self, action: #selector(didPressContextMenu), for: .menuActionTriggered)
        } else {
            contextMenuButton.addTarget(self, action: #selector(didPressContextMenu), for: .touchUpInside)
        }
        contextMenuButton.accessibilityLabel = UIConstants.strings.browserSettings
        contextMenuButton.accessibilityIdentifier = "HomeView.settingsButton"
        contextMenuButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        contextMenuButton.imageView?.snp.makeConstraints { $0.size.equalTo(UIConstants.layout.contextMenuIconSize) }
        return contextMenuButton
    }()

    var canGoBack: Bool = false {
        didSet {
            backButton.isEnabled = canGoBack
            backButton.alpha = canGoBack ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
        }
    }

    var canGoForward: Bool = false {
        didSet {
            forwardButton.isEnabled = canGoForward
            forwardButton.alpha = canGoForward ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
        }
    }

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                stopReloadButton.setImage(.stopMenu, for: .normal)
                stopReloadButton.accessibilityLabel = UIConstants.strings.browserStop
            } else {
                stopReloadButton.setImage(.refreshMenu, for: .normal)
                stopReloadButton.accessibilityLabel = UIConstants.strings.browserReload
            }
        }
    }

    var canDelete: Bool = false {
        didSet {
            deleteButton.isEnabled = canDelete
            deleteButton.alpha = canDelete ? 1 : UIConstants.layout.browserToolbarDisabledOpacity
        }
    }

    @objc private func didPressBack() {
        delegate?.browserToolsetDidPressBack(self)
    }

    @objc private func didPressForward() {
        delegate?.browserToolsetDidPressForward(self)
    }

    @objc private func didPressStopReload() {
        if isLoading {
            delegate?.browserToolsetDidPressStop(self)
        } else {
            delegate?.browserToolsetDidPressReload(self)
        }
    }

    @objc func didPressDelete() {
        if canDelete {
            delegate?.browserToolsetDidPressDelete(self)
        }
    }

    @objc private func didPressContextMenu(_ sender: InsetButton) {
        delegate?.browserToolsetDidPressContextMenu(self, menuButton: sender)
    }
}
