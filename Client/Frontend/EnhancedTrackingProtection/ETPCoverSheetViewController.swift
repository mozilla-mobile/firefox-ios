/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import Leanplum

/* The layout for ETP Cover Sheet
    
 |----------------|
 |            Done|
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
 |    [Button]    |
 |    [Button]    | (Bottom View)
 |----------------|
 
 */

class ETPCoverSheetViewController: UIViewController {
    // Public constants
    let viewModel = ETPViewModel()
    static let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return ETPCoverSheetViewController.theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return ETPCoverSheetViewController.theme == .dark ? .black : .white
    }
    private var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.SettingsSearchDoneButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        return button
    }()
    private lazy var topImageView: UIImageView = {
        let imgView = UIImageView(image: viewModel.etpCoverSheetmodel?.titleImage)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.etpCoverSheetmodel?.titleText
        label.textColor = fxTextThemeColour
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.etpCoverSheetmodel?.descriptionText
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var goToSettingsButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.CoverSheetETPSettingsButton, for: .normal)
        button.titleLabel?.font = UpdateViewControllerUX.StartBrowsingButton.font
        button.layer.cornerRadius = UpdateViewControllerUX.StartBrowsingButton.cornerRadius
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UpdateViewControllerUX.StartBrowsingButton.colour
        return button
    }()
    private lazy var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UpdateViewControllerUX.StartBrowsingButton.font
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.backgroundColor = .clear
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
        self.view.addSubview(doneButton)
        self.view.addSubview(titleLabel)
        self.view.addSubview(descriptionLabel)
        self.view.addSubview(goToSettingsButton)
        self.view.addSubview(startBrowsingButton)
        
        // Constraints
        setupTopView()
        setupBottomView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupTopView() {
        // Done button target setup
        doneButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)
        // Done button constraints setup
        // This button is located at top right hence top, right and height
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(UpdateViewControllerUX.DoneButton.paddingTop)
            make.right.equalToSuperview().inset(UpdateViewControllerUX.DoneButton.paddingRight)
            make.height.equalTo(UpdateViewControllerUX.DoneButton.height)
        }
        // The top imageview constraints setup
        topImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(doneButton.snp.bottom).offset(10)
            make.bottom.equalTo(goToSettingsButton.snp.top).offset(-200)
            make.height.lessThanOrEqualTo(100)
        }
        // Top title label constraints setup
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(descriptionLabel.snp.top).offset(-5)
            make.left.right.equalToSuperview().inset(20)
        }
        // Description title label constraints setup
        descriptionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(goToSettingsButton.snp.top).offset(-40)
            make.left.right.equalToSuperview().inset(20)
        }
    }
    
    private func setupBottomView() {
        // Bottom start button constraints
        goToSettingsButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewControllerUX.StartBrowsingButton.edgeInset)
            make.bottom.equalTo(startBrowsingButton.snp.top).offset(-16)
            make.height.equalTo(UpdateViewControllerUX.StartBrowsingButton.height)
        }
        // Bottom goto settings button
        goToSettingsButton.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
        // Bottom start button constraints
        startBrowsingButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(UpdateViewControllerUX.StartBrowsingButton.edgeInset)
            let h = view.frame.height
            // On large iPhone screens, bump this up from the bottom
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (h > 800 ? 60 : 20)
            make.bottom.equalTo(view.safeArea.bottom).inset(offset)
            make.height.equalTo(UpdateViewControllerUX.StartBrowsingButton.height)
        }
        // Bottom start browsing target setup
        startBrowsingButton.addTarget(self, action: #selector(startBrowsing), for: .touchUpInside)
    }
    
    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        LeanPlumClient.shared.track(event: .dismissedETPCoverSheet)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedETPCoverSheet)
    }
    
    @objc private func goToSettings() {
        viewModel.goToSettings?()
        LeanPlumClient.shared.track(event: .dismissETPCoverSheetAndGoToSettings)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissETPCoverSheetAndGoToSettings)
    }
    
    @objc private func startBrowsing() {
        viewModel.startBrowsing?()
        LeanPlumClient.shared.track(event: .dismissETPCoverSheetAndStartBrowsing)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissUpdateCoverSheetAndStartBrowsing)
    }
}

// UIViewController setup to keep it in portrait mode
extension ETPCoverSheetViewController {
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}
