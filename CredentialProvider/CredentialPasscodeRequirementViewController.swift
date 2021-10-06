/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import LocalAuthentication
import Shared

protocol CredentialPasscodeRequirementViewControllerDelegate {
    func credentialPasscodeRequirementViewControllerDidDismiss()
}

class CredentialPasscodeRequirementViewController: UIViewController {
    var delegate: CredentialPasscodeRequirementViewControllerDelegate?
    
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
    
    lazy private var warningLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper().MediumSizeRegularWeightAS
        label.text = .LoginsPasscodeRequirementWarning
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = UIColor.Photon.Red10
        label.clipsToBounds = true
        label.layer.cornerRadius = 8
        return label
    }()

    lazy private var bottomCancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        let imageWidth = button.imageView?.frame.width ?? 0.0
        button.setTitle(Strings.CancelString, for: .normal)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func addSubviews() {
        view.addSubview(logoImageView)
        view.addSubview(taglineLabel)
        view.addSubview(warningLabel)
        view.addSubview(bottomCancelButton)
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
        
        warningLabel.snp.makeConstraints { make in
            make.top.equalTo(taglineLabel.snp_bottomMargin).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(344)
        }

        bottomCancelButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(10)
            make.height.equalTo(44)
            make.left.equalToSuperview().inset(20)
            make.right.equalToSuperview().inset(20)
        }
    }
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.credentialPasscodeRequirementViewControllerDidDismiss()
    }
}
