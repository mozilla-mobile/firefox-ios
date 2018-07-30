/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol BrowserToolsetDelegate: class {
    func browserToolsetDidPressBack(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressForward(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressReload(_ browserToolbar: BrowserToolset)
    func browserToolsetDidLongPressReload(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressStop(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset)
}

class BrowserToolset {
    weak var delegate: BrowserToolsetDelegate?

    let backButton = InsetButton()
    let forwardButton = InsetButton()
    let stopReloadButton = InsetButton()
    let settingsButton = InsetButton()

    init() {
        backButton.tintColor = UIConstants.colors.toolbarButtonNormal
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active").alpha(0.4), for: .disabled)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        backButton.accessibilityLabel = UIConstants.strings.browserBack
        backButton.isEnabled = false

        forwardButton.tintColor = UIConstants.colors.toolbarButtonNormal
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .normal)
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active").alpha(0.4), for: .disabled)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        forwardButton.accessibilityLabel = UIConstants.strings.browserForward
        forwardButton.isEnabled = false

        stopReloadButton.tintColor = UIConstants.colors.toolbarButtonNormal
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu"), for: .normal)
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_refresh_menu").alpha(0.4), for: .disabled)
        stopReloadButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
        let longPressGestureStopReloadButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressReload))
        stopReloadButton.addGestureRecognizer(longPressGestureStopReloadButton)
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stopReloadButton.accessibilityIdentifier = "BrowserToolset.stopReloadButton"
        
        settingsButton.tintColor = UIConstants.colors.toolbarButtonNormal
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        settingsButton.accessibilityLabel = UIConstants.strings.browserSettings
        settingsButton.accessibilityIdentifier = "HomeView.settingsButton"
        settingsButton.contentEdgeInsets = UIConstants.layout.toolbarButtonInsets
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
    
    @objc func didLongPressReload(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began && !isLoading {
            stopReloadButton.alpha = 1
            delegate?.browserToolsetDidLongPressReload(self)
        }
    }

    @objc private func didPressSettings() {
        delegate?.browserToolsetDidPressSettings(self)
    }
    
    func setHighlightWhatsNew(shouldHighlight: Bool) {
        if shouldHighlight {
            settingsButton.setImage(UIImage(named: "preferences_updated"), for: .normal)
        } else {
            settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
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

extension UIImage{

    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
