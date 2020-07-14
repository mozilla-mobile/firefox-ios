/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit

/* The layout for update view controller.

[Top View] and [Stack View] are put together in another
uiview called combined view mainly to put the whole thing
in the middle of the screen.
 
|----------------|
|           Cross| Cross button is on top right corner
|                |
|----------------|----------[Combined View]--------------
|                |
|     Image      | [Top View]
|                |      -- Has title image view
|Title Multiline |      -- Title label view
|----------------|
|                | [Stack View] - Fixed height and
|                |  contains subviews with title and description
|     Title      |  -- automaticPrivacyView
|   Description  |      -- Title & Description label uiviews
|                |
|     Title      |  -- fastSearchView
|   Description  |      -- Title & Description label uiviews
|                |
|     Title      |  -- safeSyncView
|   Description  |      -- Title & Description label uiviews
|                |
|----------------|----------[Combined View]--------------
|                |
|    [Next]      | Bottom View - Only Has next button
|----------------|

*/

class IntroScreenWelcomeViewV2: UIView, CardTheme {
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return theme == .dark ? UIColor.Firefox.DarkGrey10 : .white
    }
    private lazy var titleImageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "splash"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CardTitleWelcome
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "close-large"), for: .normal)
        if #available(iOS 13, *) {
            closeButton.tintColor = .secondaryLabel
        } else {
            closeButton.tintColor = .black
        }
        return closeButton
    }()
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.IntroNextButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    // Welcome card items share same type of label hence combining them into a
    // struct so we can reuse it
    private struct WelcomeUICardItem {
        var title: String
        var description: String
        var titleColour: UIColor
        var descriptionColour: UIColor
        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.textColor = titleColour
            label.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
            label.textAlignment = .left
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        lazy var descriptionLabel: UILabel = {
            let label = UILabel()
            label.text = description
            label.textColor = descriptionColour
            label.font = UIFont.systemFont(ofSize: 19, weight: .regular)
            label.textAlignment = .left
            label.numberOfLines = 2
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
    }
    private lazy var welcomeCardItems: [WelcomeUICardItem] = {
        var cardItems = [WelcomeUICardItem]()
        // Automatic Privacy
        let automaticPrivacy = WelcomeUICardItem(title: Strings.CardTitleAutomaticPrivacy, description: Strings.CardDescriptionAutomaticPrivacy, titleColour: fxTextThemeColour, descriptionColour: fxTextThemeColour)
        cardItems.append(automaticPrivacy)
        // Fast Search
        let fastSearch = WelcomeUICardItem(title: Strings.CardTitleFastSearch, description: Strings.CardDescriptionFastSearch, titleColour: fxTextThemeColour, descriptionColour: fxTextThemeColour)
        cardItems.append(fastSearch)
        // Safe Sync
        let safeSync = WelcomeUICardItem(title: Strings.CardTitleSafeSync, description: Strings.CardDescriptionSafeSync, titleColour: fxTextThemeColour, descriptionColour: fxTextThemeColour)
        cardItems.append(safeSync)
        return cardItems
    }()
    // See above for explanation of each of these views
    private var topView = UIView()
    private var automaticPrivacyView = UIView()
    private var fastSearchView = UIView()
    private var safeSyncView = UIView()
    private var itemStackView = UIStackView()
    private var combinedView = UIView()
    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()
    // Closure delegates
    var nextClosure: (() -> Void)?
    var closeClosure: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialViewSetup()
        topViewSetup()
        stackViewSetup()
        combinedViewSetup()
    }
    
    // MARK: View setup
    private func initialViewSetup() {
        // Adding close button
        addSubview(closeButton)
        // Top view
        topView.addSubview(titleImageView)
        topView.addSubview(titleLabel)
        // Stack View
        // Automatic Privacy
        automaticPrivacyView.addSubview(welcomeCardItems[0].titleLabel)
        automaticPrivacyView.addSubview(welcomeCardItems[0].descriptionLabel)
        // Fast Search
        fastSearchView.addSubview(welcomeCardItems[1].titleLabel)
        fastSearchView.addSubview(welcomeCardItems[1].descriptionLabel)
        // Safe Sync
        safeSyncView.addSubview(welcomeCardItems[2].titleLabel)
        safeSyncView.addSubview(welcomeCardItems[2].descriptionLabel)
        // Adding all three items to tem stack view
        // Automatic Privacy + Fast Search + Safe Sync
        itemStackView.axis = .vertical
        itemStackView.distribution = .fillProportionally
        itemStackView.addArrangedSubview(automaticPrivacyView)
        itemStackView.addArrangedSubview(fastSearchView)
        itemStackView.addArrangedSubview(safeSyncView)
        // Adding [Top View] and [Stack View] together put in a combined view
        combinedView.addSubview(topView)
        combinedView.addSubview(itemStackView)
        addSubview(combinedView)
        // Adding next button
        addSubview(nextButton)
    }
    
    private func topViewSetup() {
        // Background colour setup
        backgroundColor = fxBackgroundThemeColour
        // Close button target and constraints
        closeButton.addTarget(self, action: #selector(dismissAnimated), for: .touchUpInside)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.right.equalToSuperview().inset(10)
        }
        // Top view constraints
        topView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(-20)
            make.left.right.equalToSuperview()
            make.height.equalToSuperview().dividedBy(2.4)
        }
        // Title image constraints
        titleImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            // changing offset for smaller screen Eg. iPhone 5
            let offsetValue = screenSize.height > 570 ? 40 : 10
            make.top.equalToSuperview().offset(offsetValue)
            make.height.equalToSuperview().dividedBy(2)
        }
        // Title label constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleImageView.snp.bottom).offset(23)
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
        }
    }
    
    private func stackViewSetup() {
        // Item stack view constraints
        itemStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(320)
            // changing inset for smaller screen Eg. iPhone 5
            let insetValue = screenSize.height > 570 ? -10 : 4
            make.top.equalTo(topView.snp.bottom).inset(insetValue)
        }
        // Automatic privacy
        welcomeCardItems[0].titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview()
        }
        welcomeCardItems[0].descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(welcomeCardItems[0].titleLabel.snp.bottom).offset(2)
        }
        // Fast Search
        welcomeCardItems[1].titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview()
        }
        welcomeCardItems[1].descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(welcomeCardItems[1].titleLabel.snp.bottom).offset(2)
        }
        // Safe Sync
        welcomeCardItems[2].titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview()
        }
        welcomeCardItems[2].descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalTo(welcomeCardItems[2].titleLabel.snp.bottom).offset(2)
        }
    }
    
    private func combinedViewSetup() {
        // Combined top view and stack view constraints
        combinedView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalToSuperview().dividedBy(1.3)
        }
        // Next Button bottom action and constraints
        nextButton.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(safeArea.bottom).inset(10)
            make.height.equalTo(30)
        }
    }
    
    // MARK: Button Actions
    @objc private func dismissAnimated() {
        LeanPlumClient.shared.track(event: .dismissedOnboarding, withParameters: ["dismissedOnSlide": "0"])
         TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboarding, extras: ["slide-num": 0])
        closeClosure?()
    }
    
    @objc private func nextAction() {
        nextClosure?()
    }
}
