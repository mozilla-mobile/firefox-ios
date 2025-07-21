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
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = 8
        static let maxSheetWidth: CGFloat = 500
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private let viewModel: ToUBottomSheetViewModel
    private let grabberView = UIView()
    private let sheetContainer = UIView()
    private var stackView: UIStackView!

    init(viewModel: ToUBottomSheetViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: UUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIAccessibility.post(notification: .announcement, argument: "Terms of Use sheet opened")

        setupBackground()
        setupSheetContainer()
        setupGrabber()
        setupContentStack()
        setupDismissGesture()
        setupPanGesture()

        listenForThemeChange(view)
        applyTheme()
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    func applyTheme() {
        sheetContainer.backgroundColor = currentTheme().colors.layer1
    }

    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    private func setupSheetContainer() {
        sheetContainer.layer.cornerRadius = UX.cornerRadius
        sheetContainer.clipsToBounds = true
        sheetContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(sheetContainer)

        var constraints = [
            sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        if UIDevice.current.userInterfaceIdiom == .pad {
            constraints.append(sheetContainer.widthAnchor.constraint(lessThanOrEqualToConstant: UX.maxSheetWidth))
            constraints.append(sheetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupGrabber() {
        grabberView.backgroundColor = UIColor.systemGray3
        grabberView.layer.cornerRadius = UX.grabberHeight / 2
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.addSubview(grabberView)

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: UX.grabberHeight)
        ])
    }

    private func setupContentStack() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UX.stackSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        sheetContainer.addSubview(stackView)


        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: UX.stackSidePadding),
            stackView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -UX.stackSidePadding),
            stackView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: UX.stackSpacing),
            stackView.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor, constant: -UX.stackSidePadding)
        ])

       
        let logoImageView = createLogoImageView()
        let titleLabel = createTitleLabel()
        let descriptionTextView = createDescriptionTextView()
        let acceptButton = createAcceptButton()
        let remindMeLaterButton = createRemindMeLaterButton()
        
        [logoImageView, titleLabel, descriptionTextView, acceptButton, remindMeLaterButton].forEach {
            stackView.addArrangedSubview($0)
        }
        setupAccessibilityIdentifiers(logoImageView, titleLabel, descriptionTextView, acceptButton, remindMeLaterButton)

    }

    private func setupDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sheetContainer.addGestureRecognizer(panGesture)
    }

    @objc private func backgroundTapped(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if !sheetContainer.frame.contains(location) {
            dismiss(animated: true)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                sheetContainer.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            let velocity = gesture.velocity(in: view)
            if translation.y > 100 || velocity.y > 800 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseOut) {
                    self.sheetContainer.transform = .identity
                }
            }
        default:
            break
        }
    }

    private func createLogoImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.logo
        return imageView
    }

    private func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = viewModel.titleText
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.textAlignment = .center
        label.textColor = currentTheme().colors.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.title
        return label
    }

    private func createDescriptionTextView() -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .left
        textView.attributedText = makeAttributedText()
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.descriptionMaxWidth).isActive = true
        textView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.description
        return textView
    }

    private func createAcceptButton() -> PrimaryRoundedButton {
        let button = PrimaryRoundedButton()
        button.setTitle(viewModel.acceptButtonTitle, for: .normal)
        button.applyTheme(theme: currentTheme())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.acceptButton
        return button
    }

    private func createRemindMeLaterButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(viewModel.remindMeLaterButtonTitle, for: .normal)
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        button.tintColor = currentTheme().colors.actionPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.remindMeLaterButton
        return button
    }

    private func makeAttributedText() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left

        let attributed = NSMutableAttributedString(string: viewModel.descriptionText, attributes: [
            .font: FXFontStyles.Regular.body.scaledFont(),
            .foregroundColor: currentTheme().colors.textSecondary,
            .paragraphStyle: paragraphStyle
        ])
        let terms = [
            TermsOfUse.LinkTermsOfUse,
            TermsOfUse.LinkPrivacyNotice,
            TermsOfUse.LinkLearnMore
        ]
        print("[ToU Debug] Generated SUMO FAQ URL: \(String(describing: viewModel.linkURL(for: TermsOfUse.LinkLearnMore)))")
        for term in terms {
            if let url = viewModel.linkURL(for: term),
               let range = attributed.string.range(of: term) {
                let nsRange = NSRange(range, in: attributed.string)
                attributed.addAttribute(.link, value: url, range: nsRange)
            }
        }

        return attributed
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

    @objc private func acceptTapped() {
        viewModel.onAccept?()
        dismiss(animated: true)
    }

    @objc private func notNowTapped() {
        viewModel.onNotNow?()
        dismiss(animated: true)
    }
}

extension ToUBottomSheetViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }

        let linkVC = ToULinkViewController(url: URL, windowUUID: windowUUID)
        self.present(linkVC, animated: true)
        return false
    }
}

