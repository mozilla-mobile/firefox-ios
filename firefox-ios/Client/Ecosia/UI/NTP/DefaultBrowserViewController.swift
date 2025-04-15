// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

protocol DefaultBrowserDelegate: AnyObject {
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowserViewController)
}

final class DefaultBrowserViewController: UIViewController, Themeable {
    struct UX {
        static let imageHeight: CGFloat = 300
        static let wavesHeight: CGFloat = 92
        static let buttonHeight: CGFloat = 48
        static let checksSize: CGFloat = 24
    }

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = .ecosia.borderRadius._l
        view.clipsToBounds = true
        return view
    }()
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: DefaultBrowserExperiment.image)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()
    private lazy var waves: UIImageView = {
        let view = UIImageView(image: .init(named: "defaultBrowserWaves"))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title2).bold()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var variationContentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = .ecosia.space._1s
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        return stack
    }()
    private lazy var actionButton: UIButton = {
        let button = EcosiaPrimaryButton(windowUUID: windowUUID)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(DefaultBrowserExperiment.buttonTitle, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = UX.buttonHeight/2
        button.addTarget(self, action: #selector(clickAction), for: .primaryActionTriggered)
        return button
    }()
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(.localized(.notNow), for: .normal)
        button.addTarget(self, action: #selector(skipAction), for: .primaryActionTriggered)
        button.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return button
    }()

    // MARK: Description variation
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.description
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    // MARK: Checks variation
    private lazy var firstCheckItemLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.checkItems.0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    private lazy var secondCheckItemLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultBrowserExperiment.checkItems.1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    private lazy var firstCheckImageView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "checkmark"))
        view.contentMode = .scaleAspectFit
        view.widthAnchor.constraint(equalToConstant: UX.checksSize).isActive = true
        return view
    }()
    private lazy var secondCheckImageView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "checkmark"))
        view.contentMode = .scaleAspectFit
        view.widthAnchor.constraint(equalToConstant: UX.checksSize).isActive = true
        return view
    }()

    // MARK: Trivia variation
    private lazy var triviaView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = .ecosia.borderRadius._l
        view.clipsToBounds = true
        return view
    }()
    private lazy var triviaTitleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.defaultBrowserPromptExperimentDescriptionTitleVarBC)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body).semibold()
        return label
    }()
    private lazy var triviaDecriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = DefaultBrowserExperiment.trivia(font: .preferredFont(forTextStyle: .body))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    private lazy var beforeView: BeforeOrAfterView = {
        let view = BeforeOrAfterView(type: .before)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var afterView: BeforeOrAfterView = {
        let view = BeforeOrAfterView(type: .after)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var screenWidth: CGFloat { UIScreen.main.bounds.width }

    // MARK: Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: WindowUUID? { windowUUID }
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    weak var delegate: DefaultBrowserDelegate?
    init(windowUUID: WindowUUID, delegate: DefaultBrowserDelegate) {
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        if traitCollection.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
            preferredContentSize = .init(width: 544, height: 600)
        } else {
            modalPresentationCapturesStatusBarAppearance = true
        }
    }

    required init?(coder: NSCoder) { nil }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
       .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        applyTheme()

        listenForThemeChange(self.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.shared.defaultBrowser(.view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        self.delegate?.defaultBrowserDidShow(self)
    }

    private func setupViews() {
        view.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(waves)
        contentView.addSubview(titleLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(skipButton)
        view.addSubview(variationContentStack)

        let type = DefaultBrowserExperiment.contentType
        if case .checks = type {
            let line1 = UIStackView()
            line1.spacing = .ecosia.space._1s
            line1.axis = .horizontal
            variationContentStack.addArrangedSubview(line1)
            line1.addArrangedSubview(firstCheckImageView)
            line1.addArrangedSubview(firstCheckItemLabel)
            let line2 = UIStackView()
            line2.spacing = .ecosia.space._1s
            line2.axis = .horizontal
            variationContentStack.addArrangedSubview(line2)
            line2.addArrangedSubview(secondCheckImageView)
            line2.addArrangedSubview(secondCheckItemLabel)
        } else if case .description = type {
            variationContentStack.addArrangedSubview(descriptionLabel)
        } else if case .trivia = type {
            variationContentStack.addArrangedSubview(triviaView)
            triviaView.addSubview(triviaTitleLabel)
            triviaView.addSubview(triviaDecriptionLabel)
            contentView.addSubview(beforeView)
            contentView.addSubview(afterView)
            let padding: CGFloat = .ecosia.space._m
            NSLayoutConstraint.activate([
                triviaTitleLabel.topAnchor.constraint(equalTo: triviaView.topAnchor, constant: padding),
                triviaDecriptionLabel.topAnchor.constraint(equalTo: triviaTitleLabel.bottomAnchor, constant: padding),
                triviaDecriptionLabel.bottomAnchor.constraint(equalTo: triviaView.bottomAnchor, constant: -padding),
                triviaTitleLabel.leadingAnchor.constraint(equalTo: triviaView.leadingAnchor, constant: padding),
                triviaTitleLabel.trailingAnchor.constraint(equalTo: triviaView.trailingAnchor, constant: -padding),
                triviaDecriptionLabel.leadingAnchor.constraint(equalTo: triviaView.leadingAnchor, constant: padding),
                triviaDecriptionLabel.trailingAnchor.constraint(equalTo: triviaView.trailingAnchor, constant: -padding),

                beforeView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                afterView.centerYAnchor.constraint(equalTo: beforeView.centerYAnchor),
                beforeView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -screenWidth/4),
                afterView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: screenWidth/4)
            ])
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: UX.imageHeight),

            waves.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            waves.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            waves.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            waves.heightAnchor.constraint(equalToConstant: UX.wavesHeight),

            titleLabel.topAnchor.constraint(equalTo: waves.bottomAnchor, constant: .ecosia.space._3l),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .ecosia.space._m),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.ecosia.space._m),

            variationContentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .ecosia.space._m),
            variationContentStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            variationContentStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            actionButton.topAnchor.constraint(equalTo: variationContentStack.bottomAnchor, constant: .ecosia.space._1l).priority(.defaultLow),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            actionButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            skipButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: .ecosia.space._s),
            skipButton.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            skipButton.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            skipButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -.ecosia.space._m),
        ])
    }

    @objc func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = .clear
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        contentView.backgroundColor = theme.colors.ecosia.ntpIntroBackground
        waves.tintColor = theme.colors.ecosia.ntpIntroBackground
        actionButton.setTitleColor(theme.colors.ecosia.textInversePrimary, for: .normal)
        skipButton.setTitleColor(theme.colors.ecosia.buttonBackgroundPrimary, for: .normal)
        actionButton.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimary
        descriptionLabel.textColor = theme.colors.ecosia.textSecondary
        firstCheckItemLabel.textColor = theme.colors.ecosia.textSecondary
        secondCheckItemLabel.textColor = theme.colors.ecosia.textSecondary
        firstCheckImageView.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
        secondCheckImageView.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
        triviaView.backgroundColor = theme.colors.ecosia.backgroundSecondary
        triviaTitleLabel.textColor = theme.colors.ecosia.textPrimary
        triviaDecriptionLabel.textColor = theme.colors.ecosia.textSecondary
        beforeView.applyTheme(theme: theme)
        afterView.applyTheme(theme: theme)
    }

    @objc private func skipAction() {
        Analytics.shared.defaultBrowser(.close)
        dismiss(animated: true)
    }

    @objc private func clickAction() {
        Analytics.shared.defaultBrowser(.click)

        dismiss(animated: true) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        }
    }
}
