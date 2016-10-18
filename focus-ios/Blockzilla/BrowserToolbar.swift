/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol BrowserToolbarDelegate: class {
    func browserToolbarDidPressBack(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressForward(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressReload(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressStop(browserToolbar: BrowserToolbar)
    func browserToolbarDidPressSend(browserToolbar: BrowserToolbar)
}

class BrowserToolbar: UIView {
    weak var delegate: BrowserToolbarDelegate?

    private let backButton = UIButton(type: .custom)
    private let forwardButton = UIButton()
    private let stopReloadButton = UIButton()
    private let sendButton = UIButton()
    private let gradient = CAGradientLayer()

    init() {
        super.init(frame: CGRect.zero)

        let backgroundView = GradientBackgroundView()
        backgroundView.alpha = 0.9
        addSubview(backgroundView)

        let borderView = UIView()
        borderView.backgroundColor = UIConstants.colors.toolbarBorder
        borderView.alpha = 0.9
        addSubview(borderView)

        let stackView = UIStackView()
        stackView.distribution = .fillEqually

        backButton.tintColor = UIConstants.colors.toolbarButtonNormal
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "icon_back_active"), for: .highlighted)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.isEnabled = false
        backButton.alpha = UIConstants.layout.browserToolbarDisabledOpacity
        stackView.addArrangedSubview(backButton)

        forwardButton.tintColor = UIConstants.colors.toolbarButtonNormal
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .normal)
        forwardButton.setImage(#imageLiteral(resourceName: "icon_forward_active"), for: .highlighted)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.isEnabled = false
        forwardButton.alpha = UIConstants.layout.browserToolbarDisabledOpacity
        stackView.addArrangedSubview(forwardButton)

        stopReloadButton.tintColor = UIConstants.colors.toolbarButtonNormal
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stackView.addArrangedSubview(stopReloadButton)

        sendButton.tintColor = UIConstants.colors.toolbarButtonNormal
        sendButton.setImage(#imageLiteral(resourceName: "icon_openwith_active"), for: .normal)
        sendButton.setImage(#imageLiteral(resourceName: "icon_openwith_active"), for: .highlighted)
        sendButton.addTarget(self, action: #selector(didPressSend), for: .touchUpInside)
        stackView.addArrangedSubview(sendButton)
        addSubview(stackView)

        borderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(1)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        backgroundView.snp.makeConstraints { make in
            make.top.equalTo(borderView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func didPressBack() {
        delegate?.browserToolbarDidPressBack(browserToolbar: self)
    }

    func didPressForward() {
        delegate?.browserToolbarDidPressForward(browserToolbar: self)
    }

    func didPressStopReload() {
        if isLoading {
            delegate?.browserToolbarDidPressStop(browserToolbar: self)
        } else {
            delegate?.browserToolbarDidPressReload(browserToolbar: self)
        }
    }

    func didPressSend() {
        delegate?.browserToolbarDidPressSend(browserToolbar: self)
    }
}
