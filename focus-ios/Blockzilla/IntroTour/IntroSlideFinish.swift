/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol IntroSlideFinishDelegate: class {
    func introSlideFinishDidPressGetStarted(introSlideFinish: IntroSlideFinish)
    func introSlideFinishDidPressOpenSettings(introSlideFinish: IntroSlideFinish)
}

class IntroSlideFinish: UIView {
    weak var delegate: IntroSlideFinishDelegate?

    private let enabledStateContainer = UIView()
    private let getStartedButton = UIButton()
    private let settingsButton = UIButton()
    private let enabledStateView = EnabledStateView()
    private let checkingStateView = CheckingStateView()
    private let disabledStateView = DisabledStateView()

    enum EnabledState {
        case Enabled
        case Disabled
        case Checking
    }

    init() {
        super.init(frame: CGRectZero)

        addSubview(enabledStateContainer)

        enabledStateView.hidden = true
        enabledStateContainer.addSubview(enabledStateView)

        checkingStateView.hidden = true
        enabledStateContainer.addSubview(checkingStateView)

        disabledStateView.hidden = true
        enabledStateContainer.addSubview(disabledStateView)

        getStartedButton.setTitle(NSLocalizedString("Get Started", comment: "Button to close the intro screen"), forState: UIControlState.Normal)
        getStartedButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        getStartedButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        getStartedButton.addTarget(self, action: "getStartedClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        getStartedButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        addSubview(getStartedButton)

        settingsButton.setTitle(UIConstants.Strings.OpenSettings, forState: UIControlState.Normal)
        settingsButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        settingsButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        settingsButton.addTarget(self, action: "settingsClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        settingsButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        addSubview(settingsButton)

        enabledStateContainer.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }

        enabledStateView.snp_makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        checkingStateView.snp_makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        disabledStateView.snp_makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        getStartedButton.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-70)
        }

        settingsButton.snp_makeConstraints { make in
            make.center.equalTo(getStartedButton)
        }

        updateButtons()
        showEnabledStateView(CheckingStateView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var enabledState = EnabledState.Checking {
        didSet {
            updateButtons()

            switch enabledState {
            case EnabledState.Enabled:
                showEnabledStateView(enabledStateView)
            case EnabledState.Disabled:
                showEnabledStateView(disabledStateView)
            case EnabledState.Checking:
                showEnabledStateView(checkingStateView)
            }
        }
    }

    private func updateButtons() {
        let enabled = enabledState == EnabledState.Enabled
        getStartedButton.animateHidden(!enabled, duration: 0.3)
        settingsButton.animateHidden(enabled, duration: 0.3)
    }

    private func showEnabledStateView(view: UIView) {
        enabledStateContainer.subviews.forEach { v in
            v.animateHidden(v != view, duration: 0.3)
        }
    }

    @objc func getStartedClicked(sender: UIButton) {
        delegate?.introSlideFinishDidPressGetStarted(self)
    }

    @objc func settingsClicked(sender: UIButton) {
        delegate?.introSlideFinishDidPressOpenSettings(self)
    }
}

private class EnabledStateView: UIView {
    init() {
        super.init(frame: CGRectZero)

        let label = UILabel()
        label.text = NSLocalizedString("Focus is enabled!", comment: "Text displayed at the final step of the intro screen")
        label.textColor = UIConstants.Colors.FocusGreen
        addSubview(label)

        let image = UIImageView(image: UIImage(named: "enabled-yes"))
        addSubview(image)

        label.snp_makeConstraints { make in
            make.center.equalTo(self)
        }

        image.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.baseline.equalTo(label.snp_top).offset(-30)
            make.height.width.equalTo(650/7)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private class DisabledStateView: UIView {
    init() {
        super.init(frame: CGRectZero)

        let label = UILabel()
        label.text = UIConstants.Strings.NotEnabledError
        label.textColor = UIConstants.Colors.FocusRed
        label.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        addSubview(label)

        let instructionsView = InstructionsView()
        addSubview(instructionsView)

        let image = UIImageView(image: UIImage(named: "enabled-no"))
        addSubview(image)

        instructionsView.snp_makeConstraints { make in
            make.center.equalTo(self)
            make.width.equalTo(220)
        }

        label.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(instructionsView.snp_top).offset(-50)
        }

        image.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.greaterThanOrEqualTo(self).offset(20)
            make.bottom.lessThanOrEqualTo(label.snp_top).offset(-20)
            make.size.lessThanOrEqualTo(650/7)
            make.width.equalTo(image.snp_height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class CheckingStateView: UIView {
    init() {
        super.init(frame: CGRectZero)

        let indicator = UIActivityIndicatorView()
        indicator.startAnimating()
        addSubview(indicator)

        let label = UILabel()
        label.text = NSLocalizedString("Checking installation…", comment: "Text displayed at the final step of the intro screen")
        label.textColor = UIConstants.Colors.FocusOrange
        addSubview(label)

        let instructionsView = InstructionsView()
        addSubview(instructionsView)

        instructionsView.snp_makeConstraints { make in
            make.center.equalTo(self)
            make.width.equalTo(220)
        }

        label.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(instructionsView.snp_top).offset(-50)
        }

        indicator.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(label.snp_top).offset(-20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
