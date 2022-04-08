/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreGraphics

protocol BrowserToolsetDelegate: AnyObject {
    func browserToolsetDidPressBack(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressForward(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressReload(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressStop(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressDelete(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressContextMenu(_ browserToolbar: BrowserToolset, menuButton: InsetButton)
}

class BrowserToolset {
    weak var delegate: BrowserToolsetDelegate?
    var shouldShowWhatsNew: Bool = false
    let backButton = InsetButton()
    let forwardButton = InsetButton()
    let stopReloadButton = InsetButton()
    let deleteButton = InsetButton()
    let contextMenuButton = InsetButton()

    init() {
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .normal)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        backButton.accessibilityLabel = UIConstants.strings.browserBack
        backButton.isEnabled = false

        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .normal)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        forwardButton.accessibilityLabel = UIConstants.strings.browserForward
        forwardButton.isEnabled = false

        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu"), for: .normal)
        stopReloadButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stopReloadButton.accessibilityIdentifier = "BrowserToolset.stopReloadButton"
        
        deleteButton.setImage(#imageLiteral(resourceName: "icon_delete"), for: .normal)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        deleteButton.isEnabled = false

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
        
       setHighlightWhatsNew(shouldHighlight: shouldShowWhatsNew)
    }

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
                stopReloadButton.setImage(#imageLiteral(resourceName: "icon_stop_menu"), for: .normal)
                stopReloadButton.accessibilityLabel = UIConstants.strings.browserStop
            } else {
                stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu"), for: .normal)
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

    func setHighlightWhatsNew(shouldHighlight: Bool) {
        contextMenuButton.setImage(UIImage(named: shouldHighlight ? "preferences_updated" : "icon_hamburger_menu"), for: .normal)
    }
}
