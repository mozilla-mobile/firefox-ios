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

struct DBOnboardingUX {
    static let textOffset = 20
    static let fontSize: CGFloat = 24
}

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
        return DefaultBrowserOnboardingViewController.theme == .dark ? UIColor(rgb: 0x1C1C1E) : .white
    }
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "close-large"), for: .normal)
        if #available(iOS 13, *) {
            closeButton.tintColor = .secondaryLabel
        } else {
            closeButton.tintColor = .black
        }
        return closeButton
    }()
    private lazy var topImageView: UIImageView = {
        let imgView = UIImageView(image: viewModel.model?.titleImage)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var textView: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var imageText: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.imageText
        label.textColor = fxTextThemeColour
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
        label.font = UIFont.systemFont(ofSize: DBOnboardingUX.fontSize)
        label.textAlignment = .left
        label.numberOfLines = 3
        return label
    }()
    private lazy var descriptionLabel1: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[1]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: DBOnboardingUX.fontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel2: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[2]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: DBOnboardingUX.fontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel3: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[3]
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: DBOnboardingUX.fontSize)
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
        textView.addSubview(titleLabel)
        textView.addSubview(descriptionText)
        textView.addSubview(descriptionLabel1)
        textView.addSubview(descriptionLabel2)
        textView.addSubview(descriptionLabel3)
        self.view.addSubview(textView)
        self.view.addSubview(goToSettingsButton)
        
        // Constraints
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupView() {
        // Close button target setup
        closeButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)
        // Close button constraints setup
        // This button is located at top right hence top, right and height
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(10)
            make.right.equalToSuperview().inset(UpdateViewControllerUX.DoneButton.paddingRight)
            make.height.equalTo(44)
        }
        // The top imageview constraints setup
        topImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(10)
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
        textView.snp.makeConstraints { make in
            make.top.equalTo(topImageView.snp.bottom).offset(DBOnboardingUX.textOffset)
            make.left.right.equalToSuperview().inset(36)
        }
        // Top title label constraints setup
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        descriptionText.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DBOnboardingUX.textOffset)
            make.left.right.equalToSuperview()
        }
        // Description title label constraints setup
        descriptionLabel1.snp.makeConstraints { make in
            make.top.equalTo(descriptionText.snp.bottom).offset(DBOnboardingUX.textOffset)
        }
        // Description title label constraints setup
        descriptionLabel2.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel1.snp.bottom).offset(DBOnboardingUX.textOffset)
        }
        // Description title label constraints setup
        descriptionLabel3.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel2.snp.bottom).offset(DBOnboardingUX.textOffset)
        }
        // Bottom settings button constraints
        goToSettingsButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewControllerUX.StartBrowsingButton.edgeInset)
            make.bottom.equalTo(view.safeArea.bottom).offset(-5)
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
