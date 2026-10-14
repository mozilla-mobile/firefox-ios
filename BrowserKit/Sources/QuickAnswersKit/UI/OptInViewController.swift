// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// One of the privacy guarantees listed on the Quick Answers opt-in screen.
struct OptInPrivacyInfo {
    let imageName: String
    let title: String
    let subtitle: String
}

private enum OptInPrivacyInfoRowUX {
    static let iconSpacing: CGFloat = 16.0
    static let iconSize: CGFloat = 30.0
    static let iconTopPadding: CGFloat = 3.0
    static let textSpacing: CGFloat = 2.0
    /// The leading offset of a row's text, so that content outside of a row can align with it.
    static let textLeadingInset = iconSize + iconSpacing
}

// TODO: - FXIOS-14720 Add Strings
/// Consent screen shown before the first Quick Answers recording. It is presented as a bottom sheet
/// and only reports the user's choice through its callbacks, the presenter owns the dismissal.
public final class OptInViewController: UIViewController, Themeable, UIAdaptivePresentationControllerDelegate {
    struct UX {
        static let contentSpacing: CGFloat = 40.0
        static let contentHorizontalPadding: CGFloat = 40.0
        static let contentTopPadding: CGFloat = 24.0
        static let contentBottomPadding: CGFloat = 40.0
        static let privacyInfoSpacing: CGFloat = 24.0
        static let privacyInfoLayoutMargins = NSDirectionalEdgeInsets(
            top: 0.0,
            leading: 8.0,
            bottom: 0.0,
            trailing: 8.0
        )
        static let learnMoreContentInsets = NSDirectionalEdgeInsets(
            top: 0.0,
            leading: OptInPrivacyInfoRowUX.textLeadingInset,
            bottom: 0.0,
            trailing: 0.0
        )
        static let continueButtonContentInsets = NSDirectionalEdgeInsets(
            top: 13.5,
            leading: 16.0,
            bottom: 13.5,
            trailing: 16.0
        )
        static let closeButtonSize: CGFloat = 30.0
        static let closeButtonPadding: CGFloat = 16.0
        static let heroImageSize: CGFloat = 80.0
        static let title = "Welcome to Quick Answers"
        static let subtitle = "Ask a question out loud, get a private answer in seconds."
        static let learnMoreTitle = "Learn more..."
        static let continueTitle = "Continue"
        static let closeButtonA11yLabel = "Close"
        static let privacyInfoItems = [
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.Large.localNetwork,
                title: "Nothing gets saved",
                subtitle: "We don’t store your audio or questions."
            ),
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.Large.cookiesSlash,
                title: "Private and anonymous",
                subtitle: "We don’t use your voice to identify you."
            ),
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.Large.globe,
                title: "No training with your data",
                subtitle: "We don’t use your data to train AI models."
            )
        ]
    }

    // MARK: - Properties
    public let themeManager: any ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: WindowUUID? { windowUUID }

    private let windowUUID: WindowUUID
    private let notificationCenter: NotificationProtocol
    private let learnMoreURL: URL?
    private let onContinue: () -> Void
    private let onLearnMore: (URL) -> Void
    private let onDismiss: () -> Void

    // MARK: - Subviews
    private lazy var closeButton: UIButton = .build {
        $0.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
        $0.accessibilityLabel = UX.closeButtonA11yLabel
        $0.addAction(UIAction { [weak self] _ in self?.onDismiss() }, for: .touchUpInside)
    }
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
    }
    private let contentStackView: UIStackView = .build {
        $0.axis = .vertical
        $0.spacing = UX.contentSpacing
    }
    private let heroContainerView: UIView = .build()
    private let heroImageView: UIImageView = .build {
        $0.image = UIImage(named: StandardImageIdentifiers.Large.audioWave)?.withRenderingMode(.alwaysTemplate)
        $0.contentMode = .scaleAspectFit
        $0.isAccessibilityElement = false
    }
    private let headerStackView: UIStackView = .build {
        $0.axis = .vertical
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title2.scaledFont()
        $0.text = UX.title
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let subtitleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.text = UX.subtitle
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let privacyInfoStackView: UIStackView = .build {
        $0.axis = .vertical
        $0.spacing = UX.privacyInfoSpacing
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = UX.privacyInfoLayoutMargins
    }
    private lazy var learnMoreButton: UIButton = .build {
        $0.configuration = .plain()
        $0.configuration?.title = UX.learnMoreTitle
        $0.configuration?.contentInsets = UX.learnMoreContentInsets
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Regular.body.scaledFont()
            outgoing.underlineStyle = .single
            return outgoing
        }
        $0.contentHorizontalAlignment = .leading
        $0.titleLabel?.adjustsFontForContentSizeCategory = true
        $0.addAction(UIAction { [weak self] _ in self?.handleLearnMore() }, for: .touchUpInside)
    }
    private lazy var continueButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.title = UX.continueTitle
        $0.configuration?.contentInsets = UX.continueButtonContentInsets
        $0.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Bold.callout.scaledFont()
            return outgoing
        }
        $0.titleLabel?.adjustsFontForContentSizeCategory = true
        $0.addAction(UIAction { [weak self] _ in self?.onContinue() }, for: .touchUpInside)
    }

    // MARK: - Init
    public init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        learnMoreURL: URL?,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.learnMoreURL = learnMoreURL
        self.notificationCenter = notificationCenter
        self.onContinue = onContinue
        self.onLearnMore = onLearnMore
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        // The choice has to be made through the buttons, so the sheet can't be dragged away.
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        setupSubviews()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    // MARK: - Setup
    private func setupSubviews() {
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(subtitleLabel)
        UX.privacyInfoItems.forEach { privacyInfoStackView.addArrangedSubview(OptInPrivacyInfoRowView(privacyInfo: $0)) }
        privacyInfoStackView.addArrangedSubview(learnMoreButton)
        contentStackView.addArrangedSubview(heroImageView)
        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(privacyInfoStackView)
        scrollView.addSubview(contentStackView)
        view.addSubviews(closeButton, scrollView, continueButton)
        learnMoreButton.isHidden = learnMoreURL == nil

        NSLayoutConstraint.activate([
            heroImageView.heightAnchor.constraint(equalToConstant: UX.heroImageSize),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonPadding),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                 constant: UX.closeButtonPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: UX.contentTopPadding),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -UX.contentSpacing),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                                      constant: UX.contentHorizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                       constant: -UX.contentHorizontalPadding),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                                    constant: -2 * UX.contentHorizontalPadding),

            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                    constant: UX.contentHorizontalPadding),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                     constant: -UX.contentHorizontalPadding),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                   constant: -UX.contentBottomPadding),
        ])
    }

    // MARK: - Actions
    private func handleLearnMore() {
        guard let learnMoreURL else { return }
        onLearnMore(learnMoreURL)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        learnMoreButton.configuration?.baseForegroundColor = theme.colors.textAccent
        continueButton.configuration?.baseBackgroundColor = theme.colors.actionPrimary
        continueButton.configuration?.baseForegroundColor = theme.colors.textInverted
        heroImageView.tintColor = theme.colors.iconAccent
        updateThemeApplicableSubviews(view, for: windowUUID)
    }
}

/// A single privacy guarantee row: an accent tinted icon next to a title and its explanation.
private final class OptInPrivacyInfoRowView: UIView, ThemeApplicable {
    private let iconImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.headline.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let subtitleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let textStackView: UIStackView = .build {
        $0.axis = .vertical
        $0.spacing = OptInPrivacyInfoRowUX.textSpacing
    }

    init(privacyInfo: OptInPrivacyInfo) {
        super.init(frame: .zero)
        iconImageView.image = UIImage(named: privacyInfo.imageName)?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = privacyInfo.title
        subtitleLabel.text = privacyInfo.subtitle
        setupSubviews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        addSubviews(iconImageView, textStackView)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: OptInPrivacyInfoRowUX.iconTopPadding),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: OptInPrivacyInfoRowUX.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: OptInPrivacyInfoRowUX.iconSize),

            textStackView.topAnchor.constraint(equalTo: topAnchor),
            textStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor,
                                                   constant: OptInPrivacyInfoRowUX.iconSpacing),
            textStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        iconImageView.tintColor = theme.colors.iconAccent
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
    }
}

@available(iOS 17, *)
#Preview {
    OptInViewController(windowUUID: .DefaultUITestingUUID, themeManager: DefaultThemeManager(sharedContainerIdentifier: ""), learnMoreURL: nil) {
        
    } onLearnMore: { URL in
        
    } onDismiss: {
        
    }
}
