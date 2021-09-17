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

    let backButton = InsetButton()
    let forwardButton = InsetButton()
    let stopReloadButton = InsetButton()
    let deleteButton = InsetButton()
    let contextMenuButton = InsetButton()

    init() {
        backButton.tintColor = .primaryText
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active").alpha(0.4), for: .disabled)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        backButton.accessibilityLabel = UIConstants.strings.browserBack
        backButton.isEnabled = false

        forwardButton.tintColor = .primaryText
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .normal)
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active").alpha(UIConstants.layout.browserToolbarDisabledOpacity), for: .disabled)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        forwardButton.accessibilityLabel = UIConstants.strings.browserForward
        forwardButton.isEnabled = false

        stopReloadButton.tintColor = .primaryText
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu"), for: .normal)
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu").alpha(UIConstants.layout.browserToolbarDisabledOpacity), for: .disabled)
        stopReloadButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stopReloadButton.accessibilityIdentifier = "BrowserToolset.stopReloadButton"
        
        deleteButton.tintColor = .primaryText
        deleteButton.setImage(#imageLiteral(resourceName: "icon_delete"), for: .normal)
        deleteButton.setImage(#imageLiteral(resourceName: "icon_delete").alpha(UIConstants.layout.browserToolbarDisabledOpacity), for: .disabled)
        deleteButton.addTarget(self, action: #selector(didPressDelete), for: .touchUpInside)
        deleteButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        deleteButton.accessibilityIdentifier = "URLBar.deleteButton"
        deleteButton.isEnabled = false

        contextMenuButton.tintColor = .primaryText
        contextMenuButton.addTarget(self, action: #selector(didPressContextMenu), for: .touchUpInside)
        contextMenuButton.accessibilityLabel = UIConstants.strings.browserSettings
        contextMenuButton.accessibilityIdentifier = "HomeView.settingsButton"
        contextMenuButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        
        setHighlightWhatsNew(shouldHighlight: shouldShowWhatsNew())
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
        if shouldHighlight {
            contextMenuButton.setImage(UIImage(named: "preferences_updated"), for: .normal)
        } else {
            contextMenuButton.setImage(UIImage(named: "icon_hamburger_menu"), for: .normal)
        }
    }
}

extension BrowserToolset: WhatsNewDelegate {
    func shouldShowWhatsNew() -> Bool {
        let counter = UserDefaults.standard.integer(forKey: AppDelegate.prefWhatsNewCounter)
        return counter != 0
    }

    func didShowWhatsNew() {
        UserDefaults.standard.set(AppInfo.shortVersion, forKey: AppDelegate.prefWhatsNewDone)
        UserDefaults.standard.removeObject(forKey: AppDelegate.prefWhatsNewCounter)
    }
}
