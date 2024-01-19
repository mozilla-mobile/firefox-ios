// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol ToolbarDelegate: AnyObject {
    func backButtonClicked()
    func forwardButtonClicked()
    func reloadButtonClicked()
    func stopButtonClicked()
}

class BrowserToolbar: UIToolbar {
    weak var toolbarDelegate: ToolbarDelegate?
    private var reloadStopButton: UIBarButtonItem!
    private var backButton: UIBarButtonItem!
    private var forwardButton: UIBarButtonItem!

    // By default the state is set to reload. We save the state to avoid setting the toolbar
    // button multiple times when a page load is in progress
    private var isReloading = true

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        backButton = UIBarButtonItem(image: UIImage(named: "Back"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(backButtonClicked))
        forwardButton = UIBarButtonItem(image: UIImage(named: "Forward"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(forwardButtonClicked))
        reloadStopButton = UIBarButtonItem(image: UIImage(named: "Reload"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(reloadButtonClicked))

        var items = [UIBarButtonItem]()
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        items.append(backButton)
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        items.append(forwardButton)
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        items.append(reloadStopButton)
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        setItems(items, animated: false)

        barTintColor = .white

        // initial state for buttons
        updateBackForwardButtons(canGoBack: false, canGoForward: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Button states

    func updateReloadStopButton(loading: Bool) {
        guard loading != isReloading else { return }
        reloadStopButton.image = loading ? UIImage(named: "Stop") : UIImage(named: "Reload")
        reloadStopButton.action = loading ? #selector(stopButtonClicked) : #selector(reloadButtonClicked)
        self.isReloading = loading
    }

    func updateBackForwardButtons(canGoBack: Bool, canGoForward: Bool) {
        backButton.isEnabled = canGoBack
        forwardButton.isEnabled = canGoForward
    }

    // MARK: - Actions

    @objc
    func backButtonClicked() {
        toolbarDelegate?.backButtonClicked()
    }

    @objc
    func forwardButtonClicked() {
        toolbarDelegate?.forwardButtonClicked()
    }

    @objc
    func reloadButtonClicked() {
        toolbarDelegate?.reloadButtonClicked()
    }

    @objc
    func stopButtonClicked() {
        toolbarDelegate?.stopButtonClicked()
    }
}
