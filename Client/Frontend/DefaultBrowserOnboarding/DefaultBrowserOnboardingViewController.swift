/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import Leanplum

/*
    
 |----------------|
 |              X |
 |                |
 |     Image      |
 |    [Centre]    | (Top View)
 |                |
 |Title Multiline |
 |                |
 |Description     |
 |Multiline       |
 |                |
 |----------------|
 |                |
 |                |
 |    [Button]    | (Bottom View)
 |----------------|
 
 */

class DefaultBrowserOnboardingViewController: UIViewController {
    // Public constants
    let viewModel = DefaultBrowserOnboardingViewModel()
    static let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return DefaultBrowserOnboardingViewController.theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return DefaultBrowserOnboardingViewController.theme == .dark ? .black : .white
    }
    private lazy var closeButton: UIButton = {
        let imgView = UIButton()
        imgView.setImage(UIImage(named: "db-close-ellipse")?.withRenderingMode(.alwaysTemplate), for: .normal)
        imgView.tintColor = UIColor.Photon.Grey20
        return imgView
    }()
    private var closeButtonImage: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "db-close"))
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var topImageView: UIImageView = {
        let imgView = UIImageView(image: viewModel.model?.titleImage)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var imageText: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.imageText
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.titleText
        label.textColor = fxTextThemeColour
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    private lazy var descriptionText: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[0]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel1: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[1]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel2: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[2]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel3: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[3]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var goToSettingsButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.CoverSheetETPSettingsButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.layer.cornerRadius = UpdateViewControllerUX.StartBrowsingButton.cornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UpdateViewControllerUX.StartBrowsingButton.colour
        return button
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }
    
    func initialViewSetup() {
        self.view.backgroundColor = fxBackgroundThemeColour
        
        // Initialize
        self.view.addSubview(topImageView)
        self.view.addSubview(imageText)
        self.view.addSubview(closeButton)
        closeButton.addSubview(closeButtonImage)
        self.view.addSubview(titleLabel)
        self.view.addSubview(descriptionText)
        self.view.addSubview(descriptionLabel1)
        self.view.addSubview(descriptionLabel2)
        self.view.addSubview(descriptionLabel3)
        self.view.addSubview(goToSettingsButton)
        
        // Constraints
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupView() {
        // Done button target setup
        closeButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)
        // Done button constraints setup
        // This button is located at top right hence top, right and height
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(UpdateViewControllerUX.DoneButton.paddingTop)
            make.right.equalToSuperview().inset(UpdateViewControllerUX.DoneButton.paddingRight)
        }
        closeButtonImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        // The top imageview constraints setup
        topImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(18)
            make.bottom.equalTo(titleLabel.snp.top).offset(-32)
            make.height.equalTo(200)
        }
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
        imageText.snp.makeConstraints { make in
            make.top.equalTo(topImageView.snp.top).offset(122.5)
            if layoutDirection == .leftToRight {
                make.left.equalTo(topImageView.snp.left).inset(50)
            } else {
                make.right.equalTo(topImageView.snp.right).inset(50)
            }
        }
        // Top title label constraints setup
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(descriptionText.snp.top).offset(-24)
            make.left.right.equalToSuperview().inset(36)
        }
        descriptionText.snp.makeConstraints { make in
            make.bottom.equalTo(descriptionLabel1.snp.top).offset(-24)
            make.left.right.equalToSuperview().inset(36)
        }
        // Description title label constraints setup
        descriptionLabel1.snp.makeConstraints { make in
            make.bottom.equalTo(descriptionLabel2.snp.top).offset(-24)
            make.left.right.equalToSuperview().inset(36)
        }
        // Description title label constraints setup
        descriptionLabel2.snp.makeConstraints { make in
            make.bottom.equalTo(descriptionLabel3.snp.top).offset(-24)
            make.left.right.equalToSuperview().inset(36)
        }
        // Description title label constraints setup
        descriptionLabel3.snp.makeConstraints { make in
            make.bottom.equalTo(goToSettingsButton.snp.top).offset(-52)
            make.left.right.equalToSuperview().inset(36)
        }
        // Bottom settings button constraints
        goToSettingsButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewControllerUX.StartBrowsingButton.edgeInset)
            make.height.equalTo(60)
        }
        // Bottom goto settings button
        goToSettingsButton.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
    }
    
    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserOnboarding)
        LeanPlumClient.shared.track(event: .dismissDefaultBrowserOnboarding)
    }
    
    @objc private func goToSettings() {
        viewModel.goToSettings?()
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserOnboarding)
        LeanPlumClient.shared.track(event: .goToSettingsDefaultBrowserOnboarding)
    }
}

// UIViewController setup to keep it in portrait mode
extension DefaultBrowserOnboardingViewController {
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}
