/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import Storage
import Shared

class DefaultBrowserCard: UIView {
    public var dismissClosure: (() -> Void)?
    lazy var title: UILabel = {
        let title = UILabel()
        title.text = "Switch your default browser"
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return title
    }()
    lazy var descriptionText: UILabel = {
        let descriptionText = UILabel()
        descriptionText.text = "Set links from websites, emails, and Messages to open automatically in Firefox."
        descriptionText.numberOfLines = 0
        descriptionText.lineBreakMode = .byWordWrapping
        descriptionText.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return descriptionText
    }()
    lazy var settingsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Go To Settings", for: .normal)
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    lazy var image: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "splash"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "nav-stop"), for: .normal)
        return closeButton
    }()
    lazy var background: UIView = {
        let background = UIView()
        background.backgroundColor = UIColor.Photon.Grey30
        background.layer.cornerRadius = 12
        background.layer.masksToBounds = true
        return background
    }()
    
    private var topView = UIView()
    private var labelView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        topView.addSubview(labelView)
        topView.addSubview(image)
        
        background.addSubview(settingsButton)
        background.addSubview(topView)
        background.addSubview(closeButton)
        
        labelView.axis = .vertical
        labelView.addArrangedSubview(title)
        labelView.addArrangedSubview(descriptionText)
        
        addSubview(background)
        
        setupConstraints()
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        background.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(210)
        }
        topView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(settingsButton.snp.top)
            make.height.equalTo(114)
        }
        image.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.right.equalTo(labelView.snp.left).offset(-18)
            make.height.width.equalTo(64)
            make.top.equalToSuperview().offset(45)
        }
        labelView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(image.snp.right)
            make.width.lessThanOrEqualTo(223)
            make.bottom.equalTo(settingsButton.snp.top).offset(-16)
            make.top.equalToSuperview().offset(20)
        }
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(16)
            make.bottom.right.equalToSuperview().offset(-16)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(303)
            make.height.equalTo(44)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.width.equalTo(15)
        }
    }
    
    private func setupButtons() {
        closeButton.addTarget(self, action: #selector(dismissCard), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
    }
    
    @objc private func dismissCard() {
        self.dismissClosure?()
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard")
    }
    
    @objc private func showSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }
}
