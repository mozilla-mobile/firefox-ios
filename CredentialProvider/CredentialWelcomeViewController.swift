/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
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
    
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AutoFill Firefox Passwords"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy private var taglineLabel: UILabel = {
        let label = UILabel()
        label.text = .LoginsWelcomeViewTitle
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
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
        button.setTitle(String.LoginsWelcomeTurnOnAutoFillButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.CredentialProvider.welcomeScreenBackgroundColor
        addSubviews()
        addViewConstraints()
    }
        
    func addSubviews() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(taglineLabel)
        view.addSubview(cancelButton)
        view.addSubview(proceedButton)
    }
    
    func addViewConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp_bottomMargin).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(35).priority(.high)
            make.width.lessThanOrEqualTo(440)
        }
        
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottomMargin).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(35).priority(.high)
            make.width.lessThanOrEqualTo(440)
        }
                
        cancelButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(20)
        }
        
        proceedButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(20)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(35).priority(.high)
            make.width.lessThanOrEqualTo(360)
        }
    }
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidCancel()
    }

    @objc func proceedButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidProceed()
    }
}
