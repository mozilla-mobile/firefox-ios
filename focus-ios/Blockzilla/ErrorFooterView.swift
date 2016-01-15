/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class ErrorFooterView: UIView {
    init() {
        super.init(frame: CGRectZero)

        backgroundColor = UIColor.blackColor()

        let upperBorder = UIView()
        upperBorder.backgroundColor = UIConstants.Colors.FocusRed
        addSubview(upperBorder)

        let notEnabledLabel = UILabel()
        notEnabledLabel.text = UIConstants.Strings.NotEnabledError
        notEnabledLabel.textColor = UIConstants.Colors.FocusRed
        notEnabledLabel.textAlignment = NSTextAlignment.Center
        notEnabledLabel.font = UIConstants.Fonts.SmallerFont
        addSubview(notEnabledLabel)

        let instructionsLabel1 = UILabel()
        let instructionsLabel1Text = NSLocalizedString("Enable %@ in", comment: "Instructions shown in main app when disabled in system settings")
        instructionsLabel1.text = String(format: instructionsLabel1Text, AppInfo.ProductName)
        instructionsLabel1.textColor = UIConstants.Colors.DefaultFont
        instructionsLabel1.font = UIConstants.Fonts.SmallerFont
        addSubview(instructionsLabel1)

        let instructionsLabel2 = UILabel()
        instructionsLabel2.text = NSLocalizedString("Settings → Safari → Content Blockers", comment: "Instructions shown in main app when disabled in system settings")
        instructionsLabel2.textColor = UIConstants.Colors.DefaultFont
        instructionsLabel2.numberOfLines = 0
        instructionsLabel2.textAlignment = NSTextAlignment.Center
        instructionsLabel2.font = UIConstants.Fonts.SmallerFont
        addSubview(instructionsLabel2)

        let settingsButton = UIButton()
        settingsButton.setTitle(UIConstants.Strings.OpenSettings, forState: UIControlState.Normal)
        settingsButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        settingsButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        settingsButton.addTarget(self, action: "settingsClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        settingsButton.titleLabel?.font = UIConstants.Fonts.SmallerFontSemibold
        addSubview(settingsButton)

        upperBorder.snp_makeConstraints { make in
            make.height.equalTo(2)
            make.top.width.equalTo(self)
        }

        notEnabledLabel.snp_makeConstraints { make in
            make.top.equalTo(self).offset(10)
            make.leading.trailing.equalTo(self)
        }

        instructionsLabel1.snp_makeConstraints { make in
            make.top.equalTo(notEnabledLabel.snp_bottom).offset(10)
            make.centerX.equalTo(self)
        }

        instructionsLabel2.snp_makeConstraints { make in
            make.top.equalTo(instructionsLabel1.snp_bottom)
            make.leading.trailing.equalTo(self)
        }

        settingsButton.snp_makeConstraints { make in
            make.top.equalTo(instructionsLabel2.snp_bottom).offset(10)
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func settingsClicked(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
}