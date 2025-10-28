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
    static let minSearchCountToTrigger = 50

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
        let view = UIImageView(image: .init(named: "defaultBrowser"))
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
        label.text = .localized(.defaultBrowserPromptExperimentTitle)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title2).bold()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var actionButton: UIButton = {
        let button = EcosiaPrimaryButton(windowUUID: windowUUID)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.defaultBrowserPromptExperimentButton), for: .normal)
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
    private lazy var triviaView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = .ecosia.borderRadius._l
        view.clipsToBounds = true
        return view
    }()
    private lazy var triviaTitleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.defaultBrowserPromptExperimentDescriptionTitle)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body).semibold()
        return label
    }()
    private lazy var triviaDecriptionLabel: UILabel = {
        let label = UILabel()
        let text = String.localized(.defaultBrowserPromptExperimentDescription)
        let highlight = String.localized(.defaultBrowserPromptExperimentDescriptionHighlight)
        label.attributedText = text.semiboldHighlight(highlight)
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
        view.addSubview(triviaView)

        triviaView.addSubview(triviaTitleLabel)
        triviaView.addSubview(triviaDecriptionLabel)
        contentView.addSubview(beforeView)
        contentView.addSubview(afterView)
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

            triviaView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .ecosia.space._m),
            triviaView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            triviaView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            actionButton.topAnchor.constraint(equalTo: triviaView.bottomAnchor, constant: .ecosia.space._1l).priority(.defaultLow),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            actionButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            skipButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: .ecosia.space._s),
            skipButton.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor),
            skipButton.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            skipButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -.ecosia.space._m),

            triviaTitleLabel.topAnchor.constraint(equalTo: triviaView.topAnchor, constant: .ecosia.space._m),
            triviaDecriptionLabel.topAnchor.constraint(equalTo: triviaTitleLabel.bottomAnchor, constant: .ecosia.space._m),
            triviaDecriptionLabel.bottomAnchor.constraint(equalTo: triviaView.bottomAnchor, constant: -.ecosia.space._m),
            triviaTitleLabel.leadingAnchor.constraint(equalTo: triviaView.leadingAnchor, constant: .ecosia.space._m),
            triviaTitleLabel.trailingAnchor.constraint(equalTo: triviaView.trailingAnchor, constant: -.ecosia.space._m),
            triviaDecriptionLabel.leadingAnchor.constraint(equalTo: triviaView.leadingAnchor, constant: .ecosia.space._m),
            triviaDecriptionLabel.trailingAnchor.constraint(equalTo: triviaView.trailingAnchor, constant: -.ecosia.space._m),

            beforeView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            afterView.centerYAnchor.constraint(equalTo: beforeView.centerYAnchor),
            beforeView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -screenWidth/4),
            afterView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: screenWidth/4)
        ])
    }

    @objc func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = .clear
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        contentView.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        waves.tintColor = theme.colors.ecosia.backgroundPrimaryDecorative
        actionButton.setTitleColor(theme.colors.ecosia.textInversePrimary, for: .normal)
        skipButton.setTitleColor(theme.colors.ecosia.buttonBackgroundPrimary, for: .normal)
        actionButton.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimary
        triviaView.backgroundColor = theme.colors.ecosia.backgroundElevation1
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

fileprivate extension String {
    func semiboldHighlight(_ highlight: String, baseFont: UIFont = .preferredFont(forTextStyle: .body)) -> NSAttributedString {
        let fullText = String(format: self, highlight)
        let attributedText = NSMutableAttributedString(string: fullText,
                                                       attributes: [.font: baseFont])
        if let range = fullText.range(of: highlight) {
            attributedText.addAttributes([
                .font: UIFont.systemFont(ofSize: baseFont.pointSize, weight: .semibold)
            ], range: .init(range, in: fullText))
        }
        return fullText.attributedText(boldString: highlight, font: baseFont)
    }
}
