/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Telemetry

protocol SearchSuggestionsPromptViewDelegate: class {
    func searchSuggestionsPromptView(_ searchSuggestionsPromptView: SearchSuggestionsPromptView, didEnable: Bool)
}

class SearchSuggestionsPromptView: UIView {
    weak var delegate: SearchSuggestionsPromptViewDelegate?
    static let respondedToSearchSuggestionsPrompt = "SearchSuggestionPrompt"
    private let buttonBorderMiddle = UIView()
    private let buttonBorderTop = UIView()
    private let disableButton = InsetButton()
    private let enableButton = InsetButton()
    private let promptContainer = UIView()
    private let promptMessage = UILabel()
    private let promptTitle = UILabel()

    init() {
        super.init(frame: CGRect.zero)
        promptContainer.backgroundColor = UIConstants.Photon.Ink80.withAlphaComponent(0.9)
        promptContainer.layer.cornerRadius = UIConstants.layout.searchSuggestionsPromptCornerRadius
        addSubview(promptContainer)

        promptContainer.snp.makeConstraints { make in
            make.top.equalTo(self).offset(UIConstants.layout.promptContainerOffset).priority(.medium)
            make.bottom.equalTo(self).offset(-UIConstants.layout.promptContainerOffset).priority(.medium)
            make.leading.equalTo(self).offset(UIConstants.layout.promptContainerPadding)
            make.trailing.equalTo(self).offset(-UIConstants.layout.promptContainerPadding)
        }

        promptTitle.text = UIConstants.strings.searchSuggestionsPromptTitle
        promptTitle.textColor = UIConstants.Photon.Grey10
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
        promptMessage.textColor = UIConstants.Photon.Grey10
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

        buttonBorderTop.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        addSubview(buttonBorderTop)

        buttonBorderTop.snp.makeConstraints { make in
            make.top.equalTo(promptMessage.snp.bottom).offset(UIConstants.layout.buttonBorderTopOffset).priority(.medium)
            make.leading.trailing.equalTo(promptContainer)
            make.height.equalTo(UIConstants.layout.buttonBorderTopHeight).priority(.medium)
        }

        buttonBorderMiddle.backgroundColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
        addSubview(buttonBorderMiddle)

        buttonBorderMiddle.snp.makeConstraints { make in
            make.top.equalTo(buttonBorderTop.snp.bottom).priority(.medium)
            make.bottom.equalTo(promptContainer).priority(.medium)
            make.width.equalTo(UIConstants.layout.buttonBorderMiddleWidth)
            make.height.equalTo(UIConstants.layout.buttonBorderMiddleHeight).priority(.medium)
            make.centerX.equalTo(self)
        }

        disableButton.accessibilityIdentifier = "SearchSuggestionsPromptView.disableButton"
        disableButton.setTitle(UIConstants.strings.searchSuggestionsPromptDisable, for: .normal)
        disableButton.titleLabel?.font = UIConstants.fonts.disableButton
        disableButton.layer.cornerRadius = UIConstants.layout.searchSuggestionsPromptButtonRadius
        disableButton.addTarget(self, action: #selector(didPressDisable), for: .touchUpInside)
        addSubview(disableButton)

        disableButton.snp.makeConstraints { make in
            make.top.equalTo(buttonBorderTop.snp.bottom)
            make.bottom.leading.equalTo(promptContainer)
            make.trailing.equalTo(buttonBorderMiddle.snp.leading)
        }

        enableButton.accessibilityIdentifier = "SearchSuggestionsPromptView.enableButton"
        enableButton.setTitle(UIConstants.strings.searchSuggestionsPromptEnable, for: .normal)
        enableButton.titleLabel?.font = UIConstants.fonts.enableButton
        enableButton.layer.cornerRadius = UIConstants.layout.searchSuggestionsPromptButtonRadius
        enableButton.addTarget(self, action: #selector(didPressEnable), for: .touchUpInside)
        addSubview(enableButton)

        enableButton.snp.makeConstraints { make in
            make.top.equalTo(buttonBorderTop.snp.bottom)
            make.bottom.trailing.equalTo(promptContainer)
            make.leading.equalTo(buttonBorderMiddle.snp.trailing)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
