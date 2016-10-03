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

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIConstants.colors.toolbarBackground

        let stackView = UIStackView()
        stackView.distribution = .fillEqually

        backButton.tintColor = UIConstants.colors.toolbarButtonNormal
        backButton.setImage(#imageLiteral(resourceName: "back"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "backPressed"), for: .highlighted)
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        backButton.isEnabled = false
        stackView.addArrangedSubview(backButton)

        forwardButton.tintColor = UIConstants.colors.toolbarButtonNormal
        forwardButton.setImage(#imageLiteral(resourceName: "forward"), for: .normal)
        forwardButton.setImage(#imageLiteral(resourceName: "forwardPressed"), for: .highlighted)
        forwardButton.addTarget(self, action: #selector(didPressForward), for: .touchUpInside)
        forwardButton.isEnabled = false
        stackView.addArrangedSubview(forwardButton)

        stopReloadButton.tintColor = UIConstants.colors.toolbarButtonNormal
        stopReloadButton.setImage(#imageLiteral(resourceName: "reload"), for: .normal)
        stopReloadButton.setImage(#imageLiteral(resourceName: "reloadPressed"), for: .highlighted)
        stopReloadButton.addTarget(self, action: #selector(didPressStopReload), for: .touchUpInside)
        stackView.addArrangedSubview(stopReloadButton)

        sendButton.tintColor = UIConstants.colors.toolbarButtonNormal
        sendButton.setImage(#imageLiteral(resourceName: "send"), for: .normal)
        sendButton.setImage(#imageLiteral(resourceName: "sendPressed"), for: .highlighted)
        sendButton.addTarget(self, action: #selector(didPressSend), for: .touchUpInside)
        stackView.addArrangedSubview(sendButton)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var canGoBack: Bool = false {
        didSet {
            backButton.isEnabled = canGoBack
        }
    }

    var canGoForward: Bool = false {
        didSet {
            forwardButton.isEnabled = canGoForward
        }
    }

    var isLoading: Bool = false {
        didSet {
            let image: UIImage
            let pressedImage: UIImage
            if isLoading {
                image = #imageLiteral(resourceName: "stop")
                pressedImage = #imageLiteral(resourceName: "stopPressed")
            } else {
                image = #imageLiteral(resourceName: "reload")
                pressedImage = #imageLiteral(resourceName: "reloadPressed")
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
