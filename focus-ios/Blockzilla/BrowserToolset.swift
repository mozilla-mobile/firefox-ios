/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol BrowserToolsetDelegate: class {
    func browserToolsetDidPressBack(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressForward(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressReload(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressStop(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressSend(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressSettings(_ browserToolbar: BrowserToolset)
}

class BrowserToolset {
    weak var delegate: BrowserToolsetDelegate?

    let backButton = UIButton()
    let forwardButton = UIButton()
    let stopReloadButton = UIButton()
    let sendButton = UIButton()
    let settingsButton = UIButton()

    init() {
        backButton.tintColor = UIConstants.colors.toolbarButtonNormal
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .highlighted)
        backButton.setImage(#imageLiteral(resourceName: "icon_back_inactive"), for: .disabled)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.alpha = UIConstants.layout.browserToolbarDisabledOpacity
        backButton.isEnabled = false

        forwardButton.tintColor = UIConstants.colors.toolbarButtonNormal
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .normal)
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .highlighted)
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_inactive"), for: .disabled)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.alpha = UIConstants.layout.browserToolbarDisabledOpacity
        forwardButton.isEnabled = false

        stopReloadButton.tintColor = UIConstants.colors.toolbarButtonNormal
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_stop_menu"), for: .normal)
        stopReloadButton.setImage(#imageLiteral(resourceName: "icon_stop_menu"), for: .highlighted)
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)

        let sendImageActive = OpenUtils.canOpenInFirefox ? #imageLiteral(resourceName: "icon_openwithfx_active") : #imageLiteral(resourceName: "icon_openwith_active")
        let sendImageInactive = OpenUtils.canOpenInFirefox ? #imageLiteral(resourceName: "icon_openwithfx_inactive") : #imageLiteral(resourceName: "icon_openwith_inactive")
        sendButton.tintColor = UIConstants.colors.toolbarButtonNormal
        sendButton.setImage(sendImageActive, for: .normal)
        sendButton.setImage(sendImageActive, for: .highlighted)
        sendButton.setImage(sendImageInactive, for: .disabled)
        sendButton.addTarget(self, action: #selector(didPressSend), for: .touchUpInside)

        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
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
            let image: UIImage
            let pressedImage: UIImage
            if isLoading {
                image = #imageLiteral(resourceName: "icon_stop_menu")
                pressedImage = #imageLiteral(resourceName: "icon_stop_menu")
            } else {
                image = #imageLiteral(resourceName: "icon_refresh_menu")
                pressedImage = #imageLiteral(resourceName: "icon_refresh_menu")
            }

            stopReloadButton.setImage(image, for: .normal)
            stopReloadButton.setImage(pressedImage, for: .highlighted)
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

    @objc private func didPressSend() {
        delegate?.browserToolsetDidPressSend(self)
    }


    @objc private func didPressSettings() {
        delegate?.browserToolsetDidPressSettings(self)
    }
}
