/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Glean

protocol SearchSuggestionsPromptViewDelegate: AnyObject {
    func searchSuggestionsPromptView(_ searchSuggestionsPromptView: SearchSuggestionsPromptView, didEnable: Bool)
}

class SearchSuggestionsPromptView: UIView {
    weak var delegate: SearchSuggestionsPromptViewDelegate?
    static let respondedToSearchSuggestionsPrompt = "SearchSuggestionPrompt"

    var heightPromptContainerConstraint = NSLayoutConstraint()

    private let promptContainer = UIView()

    private lazy var enableButton: InsetButton = {
        let button = InsetButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "SearchSuggestionsPromptView.enableButton"
        button.setTitle(UIConstants.strings.searchSuggestionsPromptEnable, for: .normal)
        button.titleLabel?.font = .body17Medium
        button.titleLabel?.textColor = .primaryText
        button.backgroundColor = .primaryDark.withAlphaComponent(0.36)
        button.layer.cornerRadius = UIConstants.layout.promptButtonHeight / 2
        button.addTarget(self, action: #selector(didPressEnable), for: .touchUpInside)
        return button
    }()

    private lazy var disableButton: InsetButton = {
        let button = InsetButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "SearchSuggestionsPromptView.disableButton"
        button.setTitle(UIConstants.strings.searchSuggestionsPromptDisable, for: .normal)
        button.titleLabel?.font = .body17Medium
        button.titleLabel?.textColor = .primaryText
        button.backgroundColor = .primaryDark.withAlphaComponent(0.36)
        button.layer.cornerRadius = UIConstants.layout.promptButtonHeight / 2
        button.addTarget(self, action: #selector(didPressDisable), for: .touchUpInside)
        return button
    }()

    private lazy var promptMessage: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(format: UIConstants.strings.searchSuggestionsPromptMessage, AppInfo.productName)
        label.textColor = .primaryText
        label.font = .body15
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var promptTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = UIConstants.strings.searchSuggestionsPromptTitle
        label.textColor = .primaryText
        label.font = .title20Bold
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    var isIpadView = false {
        didSet {
            updateUI()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        promptContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(promptContainer)
        updateUI()
        promptContainer.addSubview(promptTitle)
        promptContainer.addSubview(promptMessage)
        addSubview(disableButton)
        addSubview(enableButton)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        let topPromptTitleConstraint = promptTitle.topAnchor.constraint(equalTo: promptContainer.topAnchor, constant: UIConstants.layout.promptTitleOffset)
        topPromptTitleConstraint.priority = .defaultHigh
        let topPromptMessageConstraint = promptMessage.topAnchor.constraint(equalTo: promptTitle.bottomAnchor, constant: UIConstants.layout.promptMessageOffset)
        topPromptMessageConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            topPromptTitleConstraint,
            promptTitle.leadingAnchor.constraint(equalTo: promptContainer.leadingAnchor, constant: UIConstants.layout.promptTitlePadding),
            promptTitle.trailingAnchor.constraint(equalTo: promptContainer.trailingAnchor, constant: -UIConstants.layout.promptTitlePadding),

            topPromptMessageConstraint,
            promptMessage.leadingAnchor.constraint(equalTo: promptContainer.leadingAnchor, constant: UIConstants.layout.promptMessagePadding),
            promptMessage.trailingAnchor.constraint(equalTo: promptContainer.trailingAnchor, constant: -UIConstants.layout.promptMessagePadding),

            disableButton.topAnchor.constraint(equalTo: promptMessage.bottomAnchor, constant: UIConstants.layout.promptButtonTopOffset),
            disableButton.widthAnchor.constraint(equalToConstant: UIConstants.layout.promptButtonWidth),
            disableButton.heightAnchor.constraint(equalToConstant: UIConstants.layout.promptButtonHeight),
            disableButton.bottomAnchor.constraint(equalTo: promptContainer.bottomAnchor, constant: -UIConstants.layout.promptButtonBottomInset),
            disableButton.trailingAnchor.constraint(equalTo: promptContainer.centerXAnchor, constant: -UIConstants.layout.promptButtonCenterOffset),

            enableButton.topAnchor.constraint(equalTo: promptMessage.bottomAnchor, constant: UIConstants.layout.promptButtonTopOffset),
            enableButton.widthAnchor.constraint(equalToConstant: UIConstants.layout.promptButtonWidth),
            enableButton.heightAnchor.constraint(equalToConstant: UIConstants.layout.promptButtonHeight),
            enableButton.bottomAnchor.constraint(equalTo: promptContainer.bottomAnchor, constant: -UIConstants.layout.promptButtonBottomInset),
            enableButton.leadingAnchor.constraint(equalTo: promptContainer.centerXAnchor, constant: UIConstants.layout.promptButtonCenterOffset)
        ])
    }
    override func updateConstraints() {
        let topPromptContainerConstraint = promptContainer.topAnchor.constraint(equalTo: topAnchor)
        topPromptContainerConstraint.priority = .defaultHigh
        topPromptContainerConstraint.isActive = true

        let bottomPromptContainerConstraint = promptContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomPromptContainerConstraint.priority = .defaultHigh
        bottomPromptContainerConstraint.isActive = true

        if isIpadView {
            promptContainer.removeConstraint(heightPromptContainerConstraint)
            heightPromptContainerConstraint = promptContainer.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * UIConstants.layout.suggestionViewHeightMultiplier)
            heightPromptContainerConstraint.isActive = true
            promptContainer.addConstraint(heightPromptContainerConstraint)
            promptContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: UIConstants.layout.suggestionViewWidthMultiplier).isActive = true
            promptContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        } else {
            promptContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            promptContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
        super.updateConstraints()
    }

    private func updateUI() {
        promptContainer.backgroundColor = isIpadView ? .secondarySystemBackground.withAlphaComponent(0.95) : .foundation
        if isIpadView {
            promptContainer.layer.cornerRadius = UIConstants.layout.suggestionViewCornerRadius
            promptContainer.layer.maskedCorners =  [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            promptContainer.clipsToBounds = true
        } else {
            promptContainer.layer.cornerRadius = 0
        }
        setNeedsUpdateConstraints()
    }

    @objc
    private func didPressDisable() {
        delegate?.searchSuggestionsPromptView(self, didEnable: false)
        GleanMetrics.ShowSearchSuggestions.disabledFromPanel.record()
    }

    @objc
    private func didPressEnable() {
        delegate?.searchSuggestionsPromptView(self, didEnable: true)
        GleanMetrics.ShowSearchSuggestions.enabledFromPanel.record()
    }
}
