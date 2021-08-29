/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Telemetry

protocol SearchSuggestionsPromptViewDelegate: class {
    func searchSuggestionsPromptView(_ searchSuggestionsPromptView: SearchSuggestionsPromptView, didEnable: Bool)
}

class SearchSuggestionsPromptView: UIView {
    weak var delegate: SearchSuggestionsPromptViewDelegate?
    static let respondedToSearchSuggestionsPrompt = "SearchSuggestionPrompt"
    private let disableButton = InsetButton()
    private let enableButton = InsetButton()
    private let promptContainer = UIView()
    private let promptMessage = UILabel()
    private let promptTitle = UILabel()
    
    var isIpadView: Bool = false {
        didSet {
            updateUI(isIpadView)
        }
    }
    var shouldShowFindInPage: Bool = false {
        didSet {
            if shouldShowFindInPage{
                promptContainer.layer.maskedCorners = isIpadView ? [.layerMaxXMinYCorner, .layerMinXMinYCorner] : []
            }
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        addSubview(promptContainer)
        updateUI(isIpadView)
        
        promptTitle.text = UIConstants.strings.searchSuggestionsPromptTitle
        promptTitle.textColor = .primaryText
        promptTitle.font = UIConstants.fonts.promptTitle
        promptTitle.textAlignment = NSTextAlignment.center
        promptTitle.numberOfLines = 0
        promptTitle.lineBreakMode = .byWordWrapping
        promptContainer.addSubview(promptTitle)

        promptTitle.snp.makeConstraints { make in
            make.top.equalTo(promptContainer).offset(UIConstants.layout.promptTitleOffset).priority(.medium)
            make.leading.equalTo(promptContainer).offset(UIConstants.layout.promptTitlePadding)
            make.trailing.equalTo(promptContainer).offset(-UIConstants.layout.promptTitlePadding)
        }

        promptMessage.text = String(format: UIConstants.strings.searchSuggestionsPromptMessage, AppInfo.productName)
        promptMessage.textColor = .primaryText
        promptMessage.font = UIConstants.fonts.promptMessage
        promptMessage.textAlignment = NSTextAlignment.center
        promptMessage.numberOfLines = 0
        promptMessage.lineBreakMode = .byWordWrapping
        promptContainer.addSubview(promptMessage)

        promptMessage.snp.makeConstraints { make in
            make.top.equalTo(promptTitle.snp.bottom).offset(UIConstants.layout.promptMessageOffset).priority(.medium)
            make.leading.equalTo(promptContainer).offset(UIConstants.layout.promptMessagePadding)
            make.trailing.equalTo(promptContainer).offset(-UIConstants.layout.promptMessagePadding)
        }

        disableButton.accessibilityIdentifier = "SearchSuggestionsPromptView.disableButton"
        disableButton.setTitle(UIConstants.strings.searchSuggestionsPromptDisable, for: .normal)
        disableButton.titleLabel?.font = UIConstants.fonts.promptButton
        disableButton.titleLabel?.textColor = .primaryText
        disableButton.backgroundColor = .primaryDark.withAlphaComponent(0.36)
        disableButton.layer.cornerRadius = UIConstants.layout.promptButtonHeight / 2
        disableButton.addTarget(self, action: #selector(didPressDisable), for: .touchUpInside)
        addSubview(disableButton)

        disableButton.snp.makeConstraints { make in
            make.top.equalTo(promptMessage.snp.bottom).offset(UIConstants.layout.promptButtonTopOffset)
            make.width.equalTo(UIConstants.layout.promptButtonWidth)
            make.height.equalTo(UIConstants.layout.promptButtonHeight)
            make.bottom.equalTo(promptContainer).inset(UIConstants.layout.promptButtonBottomInset)
            make.trailing.equalTo(promptContainer.snp.centerX).offset(-UIConstants.layout.promptButtonCenterOffset)
        }

        enableButton.accessibilityIdentifier = "SearchSuggestionsPromptView.enableButton"
        enableButton.setTitle(UIConstants.strings.searchSuggestionsPromptEnable, for: .normal)
        enableButton.titleLabel?.font = UIConstants.fonts.promptButton
        enableButton.titleLabel?.textColor = .primaryText
        enableButton.backgroundColor = .primaryDark.withAlphaComponent(0.36)
        enableButton.layer.cornerRadius = UIConstants.layout.promptButtonHeight / 2
        enableButton.addTarget(self, action: #selector(didPressEnable), for: .touchUpInside)
        addSubview(enableButton)

        enableButton.snp.makeConstraints { make in
            make.top.equalTo(promptMessage.snp.bottom).offset(UIConstants.layout.promptButtonTopOffset)
            make.width.equalTo(UIConstants.layout.promptButtonWidth)
            make.height.equalTo(UIConstants.layout.promptButtonHeight)
            make.bottom.equalTo(promptContainer).inset(UIConstants.layout.promptButtonBottomInset)
            make.leading.equalTo(promptContainer.snp.centerX).offset(UIConstants.layout.promptButtonCenterOffset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateUI(_ isIpadView: Bool) {
        promptContainer.backgroundColor = isIpadView ? .primaryBackground.withAlphaComponent(0.95) : .foundation
        if isIpadView {
            promptContainer.layer.cornerRadius = UIConstants.layout.suggestionViewCornerRadius
            promptContainer.clipsToBounds = true
        } else {
            promptContainer.layer.cornerRadius = 0
        }
        promptContainer.snp.remakeConstraints { make in
            make.top.equalTo(self).priority(.medium)
            make.bottom.equalTo(self).priority(.medium)
            if isIpadView {
                make.width.equalTo(self).multipliedBy(UIConstants.layout.suggestionViewWidthMultiplier)
                make.centerX.equalTo(self)
                make.height.equalTo(UIScreen.main.bounds.height * UIConstants.layout.suggestionViewHeightMultiplier)
            } else {
                make.leading.equalTo(self)
                make.trailing.equalTo(self)
            }
        }
    }
    
    @objc private func didPressDisable() {
        delegate?.searchSuggestionsPromptView(self, didEnable: false)
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionsOff)
    }

    @objc private func didPressEnable() {
        delegate?.searchSuggestionsPromptView(self, didEnable: true)
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.searchSuggestionsOn)
    }
}
