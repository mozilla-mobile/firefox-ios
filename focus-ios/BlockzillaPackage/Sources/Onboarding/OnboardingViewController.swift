/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import DesignSystem

public class OnboardingViewController: UIViewController {
    public init(
        config: OnboardingText,
        dismissOnboardingScreen: @escaping (() -> Void)
    ) {
        self.config = config
        self.dismissOnboardingScreen = dismissOnboardingScreen
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("OnboardingViewController hasn't implemented init?(coder:)")
    }

    private let dismissOnboardingScreen: (() -> Void)
    private let config: OnboardingText

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // MARK: Mozilla Icon

    private lazy var mozillaIconImageView: UIImageView = {
        let imageView = UIImageView(image: .mozilla)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityIdentifier = "OnboardingViewController.mozillaIconImageView"
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: Title Labels

    private lazy var welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = config.onboardingTitle
        label.font = .title20Bold
        label.textColor = .primaryText
        label.accessibilityIdentifier = "OnboardingViewController.welcomeLabel"
        return label
    }()

    private lazy var subWelcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = config.onboardingSubtitle
        label.font = .footnote14
        label.textColor = .secondaryText
        label.numberOfLines = 0
        label.accessibilityIdentifier = "OnboardingViewController.subWelcomeLabel"
        return label
    }()

    // MARK: Instruction

    private func titleLabel(title: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.numberOfLines = 0
        label.font = .footnote14Bold
        label.textColor = .primaryText
        label.accessibilityIdentifier = "OnboardingViewController.instruction.titleLabel"
        return label
    }

    private func descriptionLabel(description: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = description
        label.numberOfLines = 0
        label.font = .footnote14
        label.textColor = .secondaryText
        label.accessibilityIdentifier = "OnboardingViewController.instruction.descriptionLabel"
        return label
    }

    private func imageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.snp.makeConstraints { $0.width.height.equalTo(CGFloat.iconsWidthHeight) }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "OnboardingViewController.instruction.imageView"
        return imageView
    }

    // MARK: Start Browsing Button

    private lazy var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .primaryButton
        button.setTitle(config.onboardingButtonTitle, for: .normal)
        button.titleLabel?.font = .footnote14
        button.layer.cornerRadius = 5
        button.setTitleColor(.white, for: .normal)
        button.accessibilityIdentifier = "IntroViewController.startBrowsingButton"
        button.addTarget(self, action: #selector(OnboardingViewController.didTapStartButton), for: .touchUpInside)
        return button
    }()

    // MARK: - StackViews
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topStackView, middleStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            stackView.layoutMargins = .init(top: view.frame.height / .layoutMarginTopDivider, left: view.frame.width / .layoutMarginLeadingTrailingDivider, bottom: .layoutMarginBottom, right: view.frame.width / .layoutMarginLeadingTrailingDivider)
            stackView.spacing = view.frame.height / .spacingDividerPhone
        } else {
            stackView.layoutMargins = .init(top: .layoutMarginTop, left: view.frame.width / .layoutMarginLeadingTrailingDivider, bottom: .layoutMarginBottom, right: view.frame.width / .layoutMarginLeadingTrailingDivider)
            stackView.spacing = view.frame.height / .spacingDividerPad
        }
        stackView.accessibilityIdentifier = "OnboardingViewController.mainStackView"
        return stackView
    }()

    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [mozillaIconImageView, welcomeLabel, subWelcomeLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.accessibilityIdentifier = "OnboardingViewController.topStackView"
        return stackView
    }()

    private lazy var middleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = .middleStackViewSpacing
        stackView.accessibilityIdentifier = "OnboardingViewController.middleStackView"
        return stackView
    }()

    private func instructionTextStackView(with labels: [UILabel]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .textStackViewSpacing
        stackView.accessibilityIdentifier = "OnboardingViewController.instruction.textStackView"
        return stackView
    }

    private func instructionStackView(with views: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = .middleStackViewSpacing
        stackView.accessibilityIdentifier = "OnboardingViewController.instruction.stackView"
        return stackView
    }

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if UIDevice.current.userInterfaceIdiom == .phone {
            mainStackView.layoutMargins = .init(top: size.height / .layoutMarginTopDivider, left: size.width / .layoutMarginLeadingTrailingDivider, bottom: .layoutMarginBottom, right: size.width / .layoutMarginLeadingTrailingDivider)
            mainStackView.spacing = size.height / .spacingDividerPhone
        } else {
            mainStackView.layoutMargins = .init(top: .layoutMarginTop, left: size.width / .layoutMarginLeadingTrailingDivider, bottom: .layoutMarginBottom, right: size.width / .layoutMarginLeadingTrailingDivider)
            mainStackView.spacing = size.height / .spacingDividerPad
        }

        updateStartButtonConstraints(for: size)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addSubViews()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStartButtonConstraints(for: view.frame.size)
    }

    func addSubViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        scrollView.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.width.equalTo(view)
        }

        config
            .instructions
            .map { instruction -> UIStackView in
                return instructionStackView(
                    with: [
                        imageView(image: instruction.image),
                        instructionTextStackView(
                            with: [
                                titleLabel(title: instruction.title),
                                descriptionLabel(description: instruction.subtitle)
                            ]
                        )
                    ]
                )
            }
            .forEach {
                middleStackView.addArrangedSubview($0)
            }

        mozillaIconImageView.snp.makeConstraints { $0.width.height.equalTo(60) }

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp.makeConstraints { make in
            make.height.equalTo(CGFloat.buttonHeight)
            make.bottom.equalToSuperview().inset(view.frame.height / .buttonButtomInsetDivider)
            make.leading.trailing.equalToSuperview().inset(view.frame.width / .buttonLeadingTrailingInsetDivider)
            make.top.equalTo(scrollView.snp.bottom).inset(CGFloat.buttonBottomInset)
        }
    }

    private func updateStartButtonConstraints(for size: CGSize) {
        startBrowsingButton.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(size.height / .buttonButtomInsetDivider)
            make.leading.trailing.equalToSuperview().inset(size.width / .buttonLeadingTrailingInsetDivider)
        }
    }

    @objc
    func didTapStartButton() {
        dismissOnboardingScreen()
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (UIDevice.current.userInterfaceIdiom == .phone) ? .portrait : .allButUpsideDown
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

fileprivate extension CGFloat {
    static let buttonHeight: CGFloat = 44
    static let buttonBottomInset: CGFloat = -20
    static let iconsWidthHeight: CGFloat = 20
    static let textStackViewSpacing: CGFloat = 6
    static let middleStackViewSpacing: CGFloat = 24
    static let spacingDividerPhone: CGFloat = 15
    static let spacingDividerPad: CGFloat = 28
    static let layoutMarginTopDivider: CGFloat = 10
    static let layoutMarginTop: CGFloat = 50
    static let layoutMarginLeadingTrailingDivider: CGFloat = 10
    static let layoutMarginBottom: CGFloat = 0
    static let buttonButtomInsetDivider: CGFloat = 20
    static let buttonLeadingTrailingInsetDivider: CGFloat = 5
}

public struct OnboardingText {
    let onboardingTitle: String
    let onboardingSubtitle: String
    let instructions: [Instruction]
    let onboardingButtonTitle: String

    public init(
        onboardingTitle: String,
        onboardingSubtitle: String,
        instructions: [Instruction] = [],
        onboardingButtonTitle: String
    ) {
        self.onboardingTitle = onboardingTitle
        self.onboardingSubtitle = onboardingSubtitle
        self.instructions = instructions
        self.onboardingButtonTitle = onboardingButtonTitle
    }
}

public class Instruction {
    let title: String
    let subtitle: String
    let image: UIImage

    public init(title: String, subtitle: String, image: UIImage) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}
