/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol IntroSlideFinishDelegate: class {
    func introSlideFinishDidPressGetStarted(_ introSlideFinish: IntroSlideFinish)
}

class IntroSlideFinish: UIView {
    weak var delegate: IntroSlideFinishDelegate?

    fileprivate let enabledStateContainer = UIView()
    fileprivate let getStartedButton = UIButton()
    fileprivate let enabledStateView = EnabledStateView()
    fileprivate let checkingStateView = CheckingStateView()
    fileprivate let disabledStateView = DisabledStateView()

    enum EnabledState {
        case enabled
        case disabled
        case checking
    }

    init() {
        super.init(frame: CGRect.zero)

        addSubview(enabledStateContainer)

        enabledStateView.isHidden = true
        enabledStateContainer.addSubview(enabledStateView)

        checkingStateView.isHidden = true
        enabledStateContainer.addSubview(checkingStateView)

        disabledStateView.isHidden = true
        enabledStateContainer.addSubview(disabledStateView)

        getStartedButton.setTitle(NSLocalizedString("Get Started", comment: "Button to close the intro screen"), for: UIControlState())
        getStartedButton.setTitleColor(UIConstants.colors.focusBlue, for: UIControlState())
        getStartedButton.setTitleColor(UIConstants.colors.buttonHighlight, for: UIControlState.highlighted)
        getStartedButton.addTarget(self, action: #selector(IntroSlideFinish.getStartedClicked(_:)), for: UIControlEvents.touchUpInside)
        getStartedButton.titleLabel?.font = UIConstants.fonts.defaultFontSemibold
        addSubview(getStartedButton)

        enabledStateContainer.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        enabledStateView.snp.makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        checkingStateView.snp.makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        disabledStateView.snp.makeConstraints { make in
            make.edges.equalTo(enabledStateContainer)
        }

        getStartedButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-70)
        }

        updateButtons()
        showEnabledStateView(CheckingStateView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var enabledState = EnabledState.checking {
        didSet {
            updateButtons()

            switch enabledState {
            case EnabledState.enabled:
                showEnabledStateView(enabledStateView)
            case EnabledState.disabled:
                showEnabledStateView(disabledStateView)
            case EnabledState.checking:
                showEnabledStateView(checkingStateView)
            }
        }
    }

    fileprivate func updateButtons() {
        let enabled = enabledState == EnabledState.enabled
        getStartedButton.animateHidden(!enabled, duration: 0.3)
    }

    fileprivate func showEnabledStateView(_ view: UIView) {
        enabledStateContainer.subviews.forEach { v in
            v.animateHidden(v != view, duration: 0.3)
        }
    }

    @objc func getStartedClicked(_ sender: UIButton) {
        delegate?.introSlideFinishDidPressGetStarted(self)
    }
}

private class EnabledStateView: UIView {
    init() {
        super.init(frame: CGRect.zero)

        let label = UILabel()
        let enabledText = NSLocalizedString("%@ is enabled!", comment: "Text displayed at the final step of the intro screen")
        label.text = String(format: enabledText, AppInfo.ProductName)
        label.textColor = UIConstants.colors.focusGreen
        addSubview(label)

        let image = UIImageView(image: UIImage(named: "enabled-yes"))
        addSubview(image)

        label.snp.makeConstraints { make in
            make.center.equalTo(self)
        }

        image.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.lastBaseline.equalTo(label.snp.top).offset(-30)
            make.height.width.equalTo(650/7)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private class DisabledStateView: UIView {
    init() {
        super.init(frame: CGRect.zero)

        let label = UILabel()
        label.text = UIConstants.strings.notEnabledError
        label.textColor = UIConstants.colors.focusRed
        label.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.vertical)
        addSubview(label)

        let instructionsView = InstructionsView()
        addSubview(instructionsView)

        let image = UIImageView(image: UIImage(named: "enabled-no"))
        addSubview(image)

        instructionsView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.equalTo(220)
        }

        label.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(instructionsView.snp.top).offset(-50)
        }

        image.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.greaterThanOrEqualTo(self).offset(20)
            make.bottom.lessThanOrEqualTo(label.snp.top).offset(-20)
            make.size.lessThanOrEqualTo(650/7)
            make.width.equalTo(image.snp.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class CheckingStateView: UIView {
    init() {
        super.init(frame: CGRect.zero)

        let indicator = UIActivityIndicatorView()
        indicator.startAnimating()
        addSubview(indicator)

        let label = UILabel()
        label.text = NSLocalizedString("Checking installation…", comment: "Text displayed at the final step of the intro screen")
        label.textColor = UIConstants.colors.focusOrange
        addSubview(label)

        let instructionsView = InstructionsView()
        addSubview(instructionsView)

        instructionsView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.equalTo(220)
        }

        label.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(instructionsView.snp.top).offset(-50)
        }

        indicator.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(label.snp.top).offset(-20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
