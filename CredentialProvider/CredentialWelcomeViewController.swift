/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class CredentialWelcomeViewController: UIViewController {
    
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
        if #available(iOSApplicationExtension 13.0, *) {
            loadingIndicator.style = .large
        }
        return loadingIndicator
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        view.addSubview(activityIndicator)
    }
    
    func addViewConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.9)
        }
        
        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp_bottomMargin).offset(30)
            make.centerX.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.top.equalTo(taglineLabel.snp_bottomMargin).offset(20)
            make.centerX.equalToSuperview()
        }
    }
}
