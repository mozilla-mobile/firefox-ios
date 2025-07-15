// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Localizations
import ComponentLibrary

class ToUBottomSheetViewController: UIViewController, Themeable {
    
    private struct UX {
        static let cornerRadius: CGFloat = 20
        static let stackSpacing: CGFloat = 16
        static let stackSidePadding: CGFloat = 24
        static let logoSize: CGFloat = 40
        static let descriptionMaxWidth: CGFloat = 300
        static let acceptButtonHeight: CGFloat = 44
        static let remindMeLaterButtonHeight: CGFloat = 30
    }
    
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    
    var onAccept: (() -> Void)?
    var onNotNow: (() -> Void)?
    var onLinkTapped: ((URL) -> Void)?
    
    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: UUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupView()
        applyTheme()
    }
    
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: currentWindowUUID)
    }
    
    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer1
    }
    
    private func setupView() {
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UX.stackSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let logoImageView: UIImageView = .build { imageView in
            imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
            imageView.contentMode = .scaleAspectFit
        }
        logoImageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        logoImageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = TermsOfUse.Title
        titleLabel.font = FXFontStyles.Regular.headline.scaledFont()
        titleLabel.textAlignment = .center
        titleLabel.textColor = currentTheme().colors.textPrimary
        titleLabel.numberOfLines = 0
        
        let descriptionTextView = makeDescriptionTextView()
        descriptionTextView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.descriptionMaxWidth).isActive = true
        
        let acceptButton = makePrimaryButton(title: TermsOfUse.AcceptButton)
        acceptButton.applyTheme(theme: currentTheme())
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        
        let remindMeLaterButton = makeSecondaryButton(title: TermsOfUse.RemindMeLaterButton)
        remindMeLaterButton.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionTextView)
        stackView.addArrangedSubview(acceptButton)
        stackView.addArrangedSubview(remindMeLaterButton)
        
        acceptButton.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        remindMeLaterButton.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.stackSidePadding),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.stackSidePadding),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.stackSidePadding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -UX.stackSidePadding)
        ])
        
        setupAccessibilityIdentifiers(
                logoImageView: logoImageView,
                titleLabel: titleLabel,
                descriptionTextView: descriptionTextView,
                acceptButton: acceptButton,
                remindMeLaterButton: remindMeLaterButton
            )
    }
    
    private func makeDescriptionTextView() -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.attributedText = makeAttributedText()
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
    
    private func makeAttributedText() -> NSAttributedString {
        let baseText = TermsOfUse.Description
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left
        
        let attributed = NSMutableAttributedString(string: baseText, attributes: [
            .font: FXFontStyles.Regular.body.scaledFont(),
            .foregroundColor: currentTheme().colors.textSecondary,
            .paragraphStyle: paragraphStyle
        ])
        let links: [(String, String)] = [
            (TermsOfUse.LinkTermsOfUse, "https://www.mozilla.org/about/legal/terms/firefox/"),
            (TermsOfUse.LinkPrivacyNotice, "https://www.mozilla.org/privacy/firefox/"),
            (TermsOfUse.LinkLearnMore, SupportUtils.URLForTopic("mobile-firefox-terms-of-use-faq")?.absoluteString ?? "")
        ]

        for (term, url) in links {
            if let range = attributed.string.range(of: term) {
                let nsRange = NSRange(range, in: attributed.string)
                attributed.addAttribute(.link, value: url, range: nsRange)
            }
        }
        
        return attributed
    }
    
    private func makePrimaryButton(title: String) -> PrimaryRoundedButton {
        let button = PrimaryRoundedButton()
        button.setTitle(title, for: .normal)
        button.applyTheme(theme: currentTheme())
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func makeSecondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupAccessibilityIdentifiers(
        logoImageView: UIImageView,
        titleLabel: UILabel,
        descriptionTextView: UITextView,
        acceptButton: UIButton,
        remindMeLaterButton: UIButton
    ) {
        logoImageView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.logo
        titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.title
        descriptionTextView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.description
        acceptButton.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.acceptButton
        remindMeLaterButton.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.remindMeLaterButton
    }
    
    @objc private func acceptTapped() {
        onAccept?()
        dismiss(animated: true)
    }
    
    @objc private func notNowTapped() {
        onNotNow?()
        dismiss(animated: true)
    }
}

extension ToUBottomSheetViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else {
            return true
        }
        if !isViewLoaded || ((view.window?.isKeyWindow) == nil) {
            return false
        }
        onLinkTapped?(URL)
        dismiss(animated: true)
        return false
    }
}
