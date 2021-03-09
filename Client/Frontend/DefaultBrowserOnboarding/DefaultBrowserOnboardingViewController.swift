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
    static let textOffsetSmall = 13
    static let fontSize: CGFloat = 24
    static let fontSizeSmall: CGFloat = 20
    static let fontSizeXSmall: CGFloat = 16
    static let titleSize: CGFloat = 28
    static let titleSizeSmall: CGFloat = 24
    static let titleSizeLarge: CGFloat = 34
    static let containerViewHeight = 350
    static let containerViewHeightSmall = 300
    static let containerViewHeightXSmall = 250
}

class DefaultBrowserOnboardingViewController: UIViewController {
    // Public constants
    let viewModel = DefaultBrowserOnboardingViewModel()
    let theme = ThemeManager.instance
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme.currentName == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor = UIColor.theme.onboarding.backgroundColor
    private var descriptionFontSize: CGFloat {
        return screenSize.height > 1000 ? DBOnboardingUX.fontSizeXSmall :
               screenSize.height > 668 ? DBOnboardingUX.fontSize :
               screenSize.height > 640 ? DBOnboardingUX.fontSizeSmall : DBOnboardingUX.fontSizeXSmall
    }
    private var titleFontSize: CGFloat {
        return screenSize.height > 1000 ? DBOnboardingUX.titleSizeLarge :
               screenSize.height > 640 ? DBOnboardingUX.titleSize : DBOnboardingUX.titleSizeSmall
    }
    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()
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
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.titleText
        label.font = UIFont.boldSystemFont(ofSize: titleFontSize)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    private lazy var descriptionText: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[0]
        label.font = UIFont.systemFont(ofSize: descriptionFontSize)
        label.textAlignment = .left
        label.numberOfLines = 3
        return label
    }()
    private lazy var descriptionLabel1: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[1]
        label.font = UIFont.systemFont(ofSize: descriptionFontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel2: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[2]
        label.font = UIFont.systemFont(ofSize: descriptionFontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel3: UILabel = {
        let label = UILabel()
        label.text = viewModel.model?.descriptionText[3]
        label.font = UIFont.systemFont(ofSize: descriptionFontSize)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var goToSettingsButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.CoverSheetETPSettingsButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: descriptionFontSize)
        button.layer.cornerRadius = UpdateViewControllerUX.StartBrowsingButton.cornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UpdateViewControllerUX.StartBrowsingButton.colour
        button.accessibilityIdentifier = "DefaultBrowserCard.goToSettingsButton"
        return button
    }()
    
    // Used to set the part of text in center 
    private var containerView = UIView()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Portrait orientation: lock enable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }
    
    func initialViewSetup() {
        updateTheme()
        
        // Initialize
        self.view.addSubview(topImageView)
        self.view.addSubview(imageText)
        self.view.addSubview(closeButton)
        textView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionText)
        containerView.addSubview(descriptionLabel1)
        containerView.addSubview(descriptionLabel2)
        containerView.addSubview(descriptionLabel3)
        self.view.addSubview(textView)
        self.view.addSubview(goToSettingsButton)
        
        // Constraints
        setupView()
        
        // Theme change notification
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .DisplayThemeChanged, object: nil)
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
            make.centerX.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(10)
            make.height.equalTo(200)
            make.width.equalTo(340)
        }
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
        imageText.snp.makeConstraints { make in
            make.top.equalTo(topImageView.snp.top).offset(121)
            if layoutDirection == .leftToRight {
                make.left.equalTo(topImageView.snp.left).inset(20)
            } else {
                make.right.equalTo(topImageView.snp.right).inset(20)
            }
        }
        let textOffset = screenSize.height > 668 ? DBOnboardingUX.textOffset : DBOnboardingUX.textOffsetSmall
        textView.snp.makeConstraints { make in
            make.top.equalTo(topImageView.snp.bottom).offset(textOffset)
            make.left.right.equalToSuperview().inset(36)
            make.bottom.equalTo(goToSettingsButton.snp.top)
        }
        
        let containerViewHeight = screenSize.height > 1000 ? DBOnboardingUX.containerViewHeightSmall :
                                  screenSize.height > 668 ? DBOnboardingUX.containerViewHeight :
                                  screenSize.height > 640 ? DBOnboardingUX.containerViewHeightSmall : DBOnboardingUX.containerViewHeightXSmall
        let containerViewWidth = screenSize.height > 668 ? 350 : 300
        containerView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.height.equalTo(containerViewHeight)
            make.width.equalTo(containerViewWidth)
        }
        
        // Top title label constraints setup
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        descriptionText.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(textOffset)
            make.left.right.equalToSuperview()
        }
        // Description title label constraints setup
        descriptionLabel1.snp.makeConstraints { make in
            make.top.equalTo(descriptionText.snp.bottom).offset(textOffset)
        }
        // Description title label constraints setup
        descriptionLabel2.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel1.snp.bottom).offset(textOffset)
        }
        // Description title label constraints setup
        descriptionLabel3.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel2.snp.bottom).offset(textOffset)
        }
        // Bottom settings button constraints
        goToSettingsButton.snp.makeConstraints { make in
            if screenSize.height > 1000 {
                make.bottom.equalTo(view.safeArea.bottom).offset(-60)
                make.height.equalTo(50)
                make.width.equalTo(350)
            } else if screenSize.height > 640 {
                make.bottom.equalTo(view.safeArea.bottom).offset(-5)
                make.height.equalTo(60)
                make.width.equalTo(350)
            } else {
                make.bottom.equalTo(view.safeArea.bottom).offset(-5)
                make.height.equalTo(50)
                make.width.equalTo(300)
            }
            make.centerX.equalToSuperview()
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
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard") // Don't show default browser card if this button is clicked
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserOnboarding)
        LeanPlumClient.shared.track(event: .goToSettingsDefaultBrowserOnboarding)
    }
  
    // Theme
    @objc func updateTheme() {
        self.view.backgroundColor = fxBackgroundThemeColour
        self.imageText.textColor = fxTextThemeColour
        self.titleLabel.textColor = fxTextThemeColour
        self.descriptionText.textColor = fxTextThemeColour
        self.descriptionLabel1.textColor = fxTextThemeColour
        self.descriptionLabel2.textColor = fxTextThemeColour
        self.descriptionLabel3.textColor = fxTextThemeColour
        viewModel.refreshModelImage()
        self.topImageView.image = viewModel.model?.titleImage
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
