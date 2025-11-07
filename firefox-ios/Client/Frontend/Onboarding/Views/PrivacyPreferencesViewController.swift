// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import Glean

final class PrivacyPreferencesViewController: UIViewController,
                                              Themeable,
                                              Notifiable {
    struct UX {
        static let headerViewTopMargin: CGFloat = 24
        static let horizontalMargin: CGFloat = 10
        static let contentHorizontalMargin: CGFloat = 24
        static let contentDistance: CGFloat = 24
    }

    // MARK: - Properties
    private var profile: Profile
    var windowUUID: WindowUUID
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var currentWindowUUID: UUID? { windowUUID }
    var notificationCenter: NotificationProtocol
    private var glassEffectView: UIVisualEffectView?

    // MARK: - UI elements
    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.text = String(format: .Onboarding.TermsOfService.PrivacyPreferences.Title, AppName.shortName.rawValue)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    private lazy var doneButton: UIButton = .build { button in
        button.titleLabel?.font = FXFontStyles.Bold.body.scaledFont()
        button.addTarget(self, action: #selector(self.doneButtonTapped), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(.SettingsSearchDoneButton, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        if #available(iOS 26.0, *) {
            button.configuration = .glass()
        }
    }

    private lazy var contentScrollView: UIScrollView = .build()

    private lazy var contentView: UIView = .build()

    private lazy var crashReportsSwitch: SwitchDetailedView = .build { [weak self] view in
        view.setSwitchValue(isOn: self?.profile.prefs.boolForKey(AppConstants.prefSendCrashReports) ?? true)
    }

    private lazy var technicalDataSwitch: SwitchDetailedView = .build { [weak self] view in
        view.setSwitchValue(isOn: self?.profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
    }

    // MARK: - Initializers
    init(
        profile: Profile,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        setupLayout()
        setDetentSize()
        setupContentViews()
        setupCallbacks()
        setupAccessibility()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        if #available(iOS 26.0, *) {
            setupGlassEffect()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }

    // MARK: - View setup
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(doneButton)
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        contentView.addSubview(technicalDataSwitch)
        contentView.addSubview(crashReportsSwitch)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.headerViewTopMargin),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalMargin),

            doneButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: UX.horizontalMargin),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalMargin),
            doneButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            contentScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.headerViewTopMargin),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor).priority(.defaultLow),

            technicalDataSwitch.topAnchor.constraint(equalTo: contentView.topAnchor),
            technicalDataSwitch.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: UX.contentHorizontalMargin
            ),
            technicalDataSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -UX.contentHorizontalMargin
            ),

            crashReportsSwitch.topAnchor.constraint(
                equalTo: technicalDataSwitch.bottomAnchor,
                constant: UX.contentDistance
            ),
            crashReportsSwitch.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: UX.contentHorizontalMargin
            ),
            crashReportsSwitch.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -UX.contentHorizontalMargin
            ),
            crashReportsSwitch.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -UX.contentDistance)
        ])
    }

    private func setupContentViews() {
        crashReportsSwitch.setupDetails(
            actionTitle: .Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsTitle,
            actionDescription: .Onboarding.TermsOfService.PrivacyPreferences.SendCrashReportsDescription,
            linkDescription: .Onboarding.TermsOfService.PrivacyPreferences.LearnMore,
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )
        technicalDataSwitch.setupDetails(
            actionTitle: String(format: .Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataTitle,
                                MozillaName.shortName.rawValue),
            actionDescription: .Onboarding.TermsOfService.PrivacyPreferences.SendTechnicalDataDescription,
            linkDescription: .Onboarding.TermsOfService.PrivacyPreferences.LearnMore,
            useAppName: true,
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )
    }

    private func setupCallbacks() {
        crashReportsSwitch.switchCallback = { [weak self] value in
            self?.profile.prefs.setBool(value, forKey: AppConstants.prefSendCrashReports)
            TermsOfServiceTelemetry().automaticCrashReportsSwitched(to: value)
        }

        technicalDataSwitch.switchCallback = { [weak self] value in
            self?.profile.prefs.setBool(value, forKey: AppConstants.prefSendUsageData)
            self?.profile.prefs.setBool(value, forKey: AppConstants.prefStudiesToggle)
            if !value {
                GleanMetrics.Pings.shared.onboardingOptOut.submit()
            }
            TermsOfServiceTelemetry().technicalInteractionDataSwitched(to: value)
        }

        crashReportsSwitch.learnMoreCallBack = { [weak self] in
            self?.presentLink(with: SupportUtils.URLForTopic("ios-crash-reports"))
        }
        technicalDataSwitch.learnMoreCallBack = { [weak self] in
            self?.presentLink(with: SupportUtils.URLForTopic("mobile-technical-and-interaction-data"))
        }
    }

    private func setupAccessibility() {
        contentView.accessibilityElements = [technicalDataSwitch, crashReportsSwitch]
        view.accessibilityElements = [titleLabel, doneButton, contentScrollView]
        let identifiers = AccessibilityIdentifiers.TermsOfService.PrivacyNotice.self
        titleLabel.accessibilityIdentifier = identifiers.title
        doneButton.accessibilityIdentifier = identifiers.doneButton

        let crashReportViewModel = SwitchDetailedViewModel(
            contentStackViewA11yId: identifiers.CrashReports.contentStackView,
            actionContentViewA11yId: identifiers.CrashReports.actionContentView,
            actionTitleLabelA11yId: identifiers.CrashReports.actionTitleLabel,
            actionSwitchA11yId: identifiers.CrashReports.actionSwitch,
            actionDescriptionLabelA11yId: identifiers.CrashReports.actionDescriptionLabel
        )
        crashReportsSwitch.configure(viewModel: crashReportViewModel)

        let technicalDataViewModel = SwitchDetailedViewModel(
            contentStackViewA11yId: identifiers.TechnicalData.contentStackView,
            actionContentViewA11yId: identifiers.TechnicalData.actionContentView,
            actionTitleLabelA11yId: identifiers.TechnicalData.actionTitleLabel,
            actionSwitchA11yId: identifiers.TechnicalData.actionSwitch,
            actionDescriptionLabelA11yId: identifiers.TechnicalData.actionDescriptionLabel
        )
        technicalDataSwitch.configure(viewModel: technicalDataViewModel)
    }

    private func setDetentSize() {
        if UIDevice.current.userInterfaceIdiom == .phone, let sheet = sheetPresentationController {
            if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
                sheet.detents = [.large()]
            } else {
                sheet.detents = [.medium()]
            }
        }
    }

    private func presentLink(with url: URL?) {
        guard let url else { return }
        let presentLinkVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissPresentedLinkVC))
        buttonItem.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.doneButton

        presentLinkVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: presentLinkVC)
        present(controller, animated: true)
    }

    // MARK: - Button actions
    @objc
    private func dismissPresentedLinkVC() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func doneButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.setDetentSize()
            }
        default: break
        }
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        // Only set background color if glass effect is not active
        if #available(iOS 26.0, *), glassEffectView != nil {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = theme.colors.layer3
        }

        titleLabel.textColor = theme.colors.textPrimary
        if #available(iOS 26.0, *) {
            doneButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        } else {
            doneButton.setTitleColor(theme.colors.textAccent, for: .normal)
        }
        crashReportsSwitch.applyTheme(theme: theme)
        technicalDataSwitch.applyTheme(theme: theme)
        setupContentViews()
    }

    // MARK: - Glass Effect
    @available(iOS 26.0, *)
    private func setupGlassEffect() {
        // Only add glass effect if it doesn't already exist
        guard glassEffectView == nil else { return }

        let effectView = UIVisualEffectView()

        #if canImport(FoundationModels)
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = true
        effectView.effect = glassEffect
        #else
        effectView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        #endif

        effectView.clipsToBounds = true
        effectView.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = .clear
        view.insertSubview(effectView, at: 0)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: view.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        glassEffectView = effectView
    }
}
