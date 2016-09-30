/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

class BrowserViewController: UIViewController, UITextFieldDelegate {
    let webView = UIWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIConstants.colors.background

        let urlBar = UIView()
        urlBar.backgroundColor = UIConstants.colors.urlBarBackground

        view.addSubview(urlBar)
        urlBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
        }

        let urlText = URLTextField()
        urlText.font = UIConstants.fonts.urlTextFont
        urlText.textColor = UIConstants.colors.urlTextFont
        urlText.layer.cornerRadius = UIConstants.layout.urlTextCornerRadius
        urlText.backgroundColor = UIConstants.colors.urlTextBackground
        urlText.placeholder = UIConstants.strings.urlTextPlaceholder
        urlText.keyboardType = .webSearch
        urlText.autocapitalizationType = .none
        urlText.delegate = self

        urlBar.addSubview(urlText)
        urlText.snp.makeConstraints { make in
            make.top.equalTo(topLayoutGuide.snp.bottom).inset(-UIConstants.layout.urlBarInset)
            make.leading.trailing.bottom.equalTo(urlBar).inset(UIConstants.layout.urlBarInset)
        }

        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(urlBar.snp.bottom)
            make.leading.trailing.bottom.equalTo(view)
        }

        webView.loadRequest(URLRequest(url: URL(string: "https://www.google.com")!))

//        let settingsButton = UIButton()
//        settingsButton.addTarget(self, action: #selector(settingsClicked), for: .touchUpInside)
//        settingsButton.setTitle(UIConstants.Strings.LabelOpenSettings, for: .normal)
//        view.addSubview(settingsButton)
//        settingsButton.snp.makeConstraints { make in
//            make.center.equalTo(self.view)
//        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let url = "http://" + textField.text!
        webView.loadRequest(URLRequest(url: URL(string: url)!))
        return true
    }

    func settingsClicked() {
        let settingsViewController = SettingsViewController()
        present(settingsViewController, animated: true, completion: nil)
    }
}

private class URLTextField: UITextField {
    override var placeholder: String? {
        didSet {
            attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSForegroundColorAttributeName: UIConstants.colors.urlTextPlaceholder])
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: 8)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: 8)
    }
}
