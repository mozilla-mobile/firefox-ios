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
    private let viewModel: ToUBottomSheetViewModel
    private let windowUUID: WindowUUID
    private var stackView: UIStackView!

    private let sheetContainer = UIView()
    private let grabberView = UIView()
    var currentWindowUUID: UUID? { windowUUID }

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
        setupUI()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupUI() {
        setupBackground()
        setupSheetContainer()
        setupGrabber()
        setupContentStack()
        setupDismissGesture()
        setupPanGesture()
    }

    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    private func setupSheetContainer() {
        sheetContainer.layer.cornerRadius = UX.cornerRadius
        sheetContainer.clipsToBounds = true
        sheetContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetContainer)

        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        var constraints = [
            sheetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor) // ⬅️ no safeArea here
        ]

        if isPad {
            constraints.append(contentsOf: [
                sheetContainer.widthAnchor.constraint(equalToConstant: UX.maxSheetWidth),
                sheetContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
                sheetContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
            ])
        } else {
            constraints.append(contentsOf: [
                sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
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

        [createLogo(), createTitle(), createDescription(), createAcceptButton(), createRemindMeLaterButton()].forEach {
            stackView.addArrangedSubview($0)
        }
    }

    private func createLogo() -> UIImageView {
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        return imageView
    }

    private func createTitle() -> UILabel {
        let label = UILabel()
        label.text = viewModel.titleText
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.textAlignment = .center
        label.textColor = currentTheme().colors.textPrimary
        label.numberOfLines = 0
        return label
    }

    private func createDescription() -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.attributedText = viewModel.makeAttributedDescription(theme: currentTheme())
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
        textView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.descriptionMaxWidth).isActive = true
        return textView
    }

    private func createAcceptButton() -> UIButton {
        let button = PrimaryRoundedButton()
        button.setTitle(viewModel.acceptButtonTitle, for: .normal)
        button.applyTheme(theme: currentTheme())
        button.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return button
    }

    private func createRemindMeLaterButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(viewModel.remindMeLaterButtonTitle, for: .normal)
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        button.tintColor = currentTheme().colors.actionPrimary
        button.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(notNowTapped), for: .touchUpInside)
        return button
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
            if translation.y > 100 || gesture.velocity(in: view).y > 800 {
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

    @objc private func acceptTapped() {
        viewModel.onAccept?()
        dismiss(animated: true)
    }

    @objc private func notNowTapped() {
        viewModel.onNotNow?()
        dismiss(animated: true)
    }

    func applyTheme() {
        sheetContainer.backgroundColor = currentTheme().colors.layer1
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }
}

extension ToUBottomSheetViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        let linkVC = ToULinkViewController(url: url, windowUUID: windowUUID)
        present(linkVC, animated: true)
        return false
    }
}
