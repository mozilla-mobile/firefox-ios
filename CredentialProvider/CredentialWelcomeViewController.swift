/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

protocol CredentialWelcomeViewControllerDelegate {
    func credentialWelcomeViewControllerDidCancel()
    func credentialWelcomeViewControllerDidProceed()
}

class CredentialWelcomeViewController: UIViewController {
    var delegate: CredentialWelcomeViewControllerDelegate?
    
    lazy private var logoImageView: UIImageView = {
        let logoImage = UIImageView(image: UIImage(named: "logo-glyph"))
        return logoImage
    }()
    
    lazy private var taglineLabel: UILabel = {
        let label = UILabel()
        label.text = .LoginsWelcomeViewTitle
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
        
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.style = .large
        return loadingIndicator
    }()
    
    lazy private var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Strings.CancelString, for: .normal)
        button.addTarget(self, action: #selector(self.cancelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy private var proceedButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        let imageWidth = button.imageView?.frame.width ?? 0.0
        button.setTitle(String.LoginsWelcomeTurnOnAutoFillButtonTitle, for: .normal)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.CredentialProvider.welcomeScreenBackgroundColor
        addSubviews()
        addViewConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        activityIndicator.stopAnimating()
    }
    
    func addSubviews() {
        view.addSubview(logoImageView)
        view.addSubview(taglineLabel)
        view.addSubview(cancelButton)
        view.addSubview(proceedButton)
    }
    
    func addViewConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.66)
        }
        
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp_bottomMargin).offset(30)
            make.centerX.equalToSuperview()
        }
                
        cancelButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(20)
        }
        
        proceedButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(10)
            make.height.equalTo(44)
            make.left.equalToSuperview().inset(20)
            make.right.equalToSuperview().inset(20)
        }
    }
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidCancel()
    }

    @objc func proceedButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidProceed()
    }
}
