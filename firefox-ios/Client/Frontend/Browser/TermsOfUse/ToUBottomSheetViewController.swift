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

    // MARK: - Init

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupView()
        applyTheme()
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    func applyTheme() {
        view.backgroundColor = currentTheme().colors.layer1
    }

    // MARK: - Setup View

    private func setupView() {
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true

        let stackView = createStackView()
        let logoImageView = createLogoImageView()
        let titleLabel = createTitleLabel()
        let descriptionTextView = createDescriptionTextView()
        let acceptButton = createAcceptButton()
        let remindMeLaterButton = createRemindMeLaterButton()

        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionTextView)
        stackView.addArrangedSubview(acceptButton)
        stackView.addArrangedSubview(remindMeLaterButton)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.stackSidePadding),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.stackSidePadding),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.stackSidePadding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -UX.stackSidePadding)
        ])

        setupAccessibilityIdentifiers(logoImageView, titleLabel, descriptionTextView, acceptButton, remindMeLaterButton)
    }

    // MARK: - UI Elements Creation

    private func createStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UX.stackSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    private func createLogoImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        return imageView
    }

    private func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = TermsOfUse.Title
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.textAlignment = .center
        label.textColor = currentTheme().colors.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createDescriptionTextView() -> UITextView {
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
        textView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.descriptionMaxWidth).isActive = true
        return textView
    }

    private func createAcceptButton() -> PrimaryRoundedButton {
        let button = PrimaryRoundedButton()
        button.setTitle(TermsOfUse.AcceptButton, for: .normal)
        button.applyTheme(theme: currentTheme())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return button
    }

    private func createRemindMeLaterButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(TermsOfUse.RemindMeLaterButton, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        return button
    }

    // MARK: - Accessibility

    private func setupAccessibilityIdentifiers(
        _ logoImageView: UIImageView,
        _ titleLabel: UILabel,
        _ descriptionTextView: UITextView,
        _ acceptButton: UIButton,
        _ remindMeLaterButton: UIButton
    ) {
        logoImageView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.logo
        titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.title
        descriptionTextView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.description
        acceptButton.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.acceptButton
        remindMeLaterButton.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.remindMeLaterButton
    }

    // MARK: - Attributed Text

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

    // MARK: - Actions

    @objc private func acceptTapped() {
        onAccept?()
        dismiss(animated: true)
    }

    @objc private func notNowTapped() {
        onNotNow?()
        dismiss(animated: true)
    }
}

// MARK: - UITextViewDelegate

extension ToUBottomSheetViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        if !isViewLoaded || view.window?.isKeyWindow == nil { return false }
        onLinkTapped?(URL)
        dismiss(animated: true)
        return false
    }
}
