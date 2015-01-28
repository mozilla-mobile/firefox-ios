/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

protocol FxAGetStartedViewControllerDelegate {
    func didStart() -> Void
    func didCancel() -> Void
}

/**
 * An interstitial controller that shows an icon, an optional error, and
 * a button (replaced by a spinner) while another resource is loading.
 */
class FxAGetStartedViewController: UIViewController {
    var delegate: FxAGetStartedViewControllerDelegate?

    // Access this only on the main UI thread.
    var waitingForReady: Bool = true

    private var icon: UIImageView!
    private var error: UILabel!
    private var button: UIButton!
    private var spinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "didCancel")

        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue:242/255.0, alpha:1.0)

        let container = loadGetStartedView()
        container.snp_makeConstraints { make in
            make.width.equalTo(self.view)
            make.centerY.equalTo(self.view)
        }
    }

    private func loadGetStartedView() -> UIView {
        let container = UIView()
        self.view.addSubview(container)

        icon = UIImageView()
        icon.image = UIImage(named: "fxa_get_started.png")!
        container.addSubview(icon)

        error = UILabel()
        error.textColor = UIColor(red: 214/255.0, green: 57/255.0, blue: 32/255.0, alpha: 1.0)
        error.textAlignment = NSTextAlignment.Center
        error.text = " " // We want to take up space.
        error.lineBreakMode = NSLineBreakMode.ByWordWrapping
        error.numberOfLines = 0
        container.addSubview(error)

        button = UIButton.buttonWithType(UIButtonType.System) as UIButton
        button.setTitle("Get started", forState: UIControlState.Normal)
        // After clicking, we disable the button and show no message.
        button.setTitle("", forState: UIControlState.Disabled)
        button.addTarget(self, action: "didClickGetStarted", forControlEvents: UIControlEvents.TouchUpInside)
        container.addSubview(button)

        spinner = UIActivityIndicatorView()
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        spinner.frame = container.frame
        spinner.hidden = true
        container.addSubview(spinner)

        icon.snp_makeConstraints { make in
            make.top.equalTo(container)
            make.centerX.equalTo(container.snp_centerX)
            make.bottom.equalTo(self.error.snp_top).offset(-20)
        }

        error.snp_makeConstraints { make in
            make.left.right.equalTo(container).insets(UIEdgeInsetsMake(0, 30, 0, 30))
            make.bottom.equalTo(self.button.snp_top).offset(-10)
        }

        button.snp_makeConstraints { make in
            make.left.right.equalTo(container).insets(UIEdgeInsetsMake(0, 20, 0, 20))
            make.bottom.equalTo(container)
            return
        }

        // Spinner replaces button text.
        spinner.snp_makeConstraints { make in
            make.edges.equalTo(self.button)
            return
        }

        return container
    }

    func notifyReadyToStart() {
        waitingForReady = false
        if let theSpinner = self.spinner {
            if (theSpinner.isAnimating()) {
                // The user already clicked get started; we are just waiting to go.
                button.enabled = true
                spinner.hidden = true
                theSpinner.stopAnimating()
                delegate?.didStart()
            }
        }
    }

    func didClickGetStarted() {
        if (!waitingForReady) {
            delegate?.didStart()
        } else {
            // The user wants to get started as soon as possible; spin while waiting for ready.
            button.enabled = false
            spinner.hidden = false
            spinner.startAnimating()
        }
    }

    func didCancel() {
        delegate?.didCancel()
    }

    func showError(error: String) {
        button.enabled = false
        self.error.text = error
    }

    func hideError() {
        button.enabled = true
        self.error.text = " "
    }
}
