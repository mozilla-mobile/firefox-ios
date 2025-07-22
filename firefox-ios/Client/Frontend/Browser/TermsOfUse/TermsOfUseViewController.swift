// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

final class TermsOfUseViewController: UIViewController, Themeable, UITextViewDelegate {
    private struct UX {
        static let cornerRadius: CGFloat = 20
        static let stackSpacing: CGFloat = 16
        static let stackSidePadding: CGFloat = 24
        static let sheetContainerSidePadding: CGFloat = 40
        static let logoSize: CGFloat = 40
        static let acceptButtonHeight: CGFloat = 44
        static let acceptButtonCornerRadius: CGFloat = 12
        static let remindMeLaterButtonHeight: CGFloat = 30
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = 8
        static let iPadWidthMultiplier: CGFloat = 0.6
        static let panDismissDistance: CGFloat = 100
        static let panDismissVelocity: CGFloat = 800
        static let animationDuration: TimeInterval = 0.25
        static let springDamping: CGFloat = 0.8
        static let initialSpringVelocity: CGFloat = 1
        static let backgroundAlpha: CGFloat = 0.6

        static let titleFont = FXFontStyles.Regular.headline.scaledFont()
        static let descriptionFont = FXFontStyles.Regular.body.scaledFont()
        static let acceptButtonFont = FXFontStyles.Regular.callout.scaledFont()
        static let remindMeLaterFont = FXFontStyles.Regular.body.scaledFont()
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private let viewModel: TermsOfUseViewModel
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private var activeContainerConstraints: [NSLayoutConstraint] = []

    private lazy var sheetContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var grabberView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UX.grabberHeight / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UX.stackSpacing
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = viewModel.titleText
        label.font = UX.titleFont
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.attributedText = makeAttributedDescription()
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
        return textView
    }()

    private lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(viewModel.acceptButtonTitle, for: .normal)
        button.titleLabel?.font = UX.acceptButtonFont
        button.layer.cornerRadius = UX.acceptButtonCornerRadius
        button.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return button
    }()

    private lazy var remindMeLaterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(viewModel.remindMeLaterButtonTitle, for: .normal)
        button.titleLabel?.font = UX.remindMeLaterFont
        button.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(remindMeLaterTapped), for: .touchUpInside)
        return button
    }()

    init(viewModel: TermsOfUseViewModel,
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
        setupUI()
        listenForThemeChange(view)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.markToUAppeared()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupConstraints()
            view.layoutIfNeeded()
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(UX.backgroundAlpha)
        view.addSubview(sheetContainer)
        sheetContainer.addSubview(grabberView)
        sheetContainer.addSubview(stackView)
        setupConstraints()
        setupDismissGesture()
        setupPanGesture()
        addStackSubviews()
    }

    private func setupConstraints() {
        NSLayoutConstraint.deactivate(activeContainerConstraints)

        var containerConstraints = [
            sheetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        if traitCollection.horizontalSizeClass == .regular {
            containerConstraints.append(contentsOf: [
                sheetContainer.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * UX.iPadWidthMultiplier),
                sheetContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                        constant: UX.sheetContainerSidePadding),
                sheetContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                         constant: -UX.sheetContainerSidePadding)
            ])
        } else {
            containerConstraints.append(contentsOf: [
                sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate(containerConstraints)
        activeContainerConstraints = containerConstraints

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: UX.grabberHeight),

            stackView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: UX.stackSidePadding),
            stackView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -UX.stackSidePadding),
            stackView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: UX.stackSpacing),
            stackView.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor, constant: -UX.stackSidePadding)
        ])
    }

    private func addStackSubviews() {
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionTextView)
        stackView.addArrangedSubview(acceptButton)
        stackView.addArrangedSubview(remindMeLaterButton)
    }

    private func makeAttributedDescription() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left

        let attributed = NSMutableAttributedString(
            string: viewModel.combinedText,
            attributes: [
                .font: UX.descriptionFont,
                .foregroundColor: currentTheme().colors.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )

        for term in viewModel.linkTerms {
            if let url = viewModel.linkURL(for: term),
               let range = attributed.string.range(of: term) {
                let nsRange = NSRange(range, in: attributed.string)
                attributed.addAttribute(.link, value: url, range: nsRange)
            }
        }
        return attributed
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
        if !sheetContainer.frame.contains(sender.location(in: view)) {
            dismiss(animated: true)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed where translation.y > 0:
            sheetContainer.transform = CGAffineTransform(translationX: 0, y: translation.y)
        case .ended:
            if translation.y > UX.panDismissDistance || gesture.velocity(in: view).y > UX.panDismissVelocity {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: UX.animationDuration,
                               delay: 0,
                               usingSpringWithDamping: UX.springDamping,
                               initialSpringVelocity: UX.initialSpringVelocity,
                               options: .curveEaseOut) {
                    self.sheetContainer.transform = .identity
                }
            }
        default:
            break
        }
    }

    @objc private func acceptTapped() {
        viewModel.onAccept?()
        dismiss(animated: true)
    }

    @objc private func remindMeLaterTapped() {
        viewModel.onNotNow?()
        dismiss(animated: true)
    }

    func applyTheme() {
        sheetContainer.backgroundColor = currentTheme().colors.layer1
        grabberView.backgroundColor = currentTheme().colors.iconDisabled
        titleLabel.textColor = currentTheme().colors.textPrimary
        acceptButton.tintColor = currentTheme().colors.textOnDark
        acceptButton.backgroundColor = currentTheme().colors.actionPrimary
        remindMeLaterButton.tintColor = currentTheme().colors.actionPrimary
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    // MARK: TextView Delegate

    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        let linkVC = TermsOfUseLinkViewController(url: url, windowUUID: windowUUID)
        present(linkVC, animated: true)
        return false
    }
}
