// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Redux
import Shared

final class MicrosurveyViewController: UIViewController,
                                 UITableViewDataSource,
                                 UITableViewDelegate,
                                 Themeable,
                                 StoreSubscriber,
                                 Notifiable {
    typealias SubscriberStateType = MicrosurveyState

    // MARK: Themable Variables
    var themeManager: Common.ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: Common.NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    weak var coordinator: MicrosurveyCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let model: MicrosurveyModel
    private var microsurveyState: MicrosurveyState
    private var selectedOption: String?

    // MARK: UI Elements
    private struct UX {
        static let headerStackSpacing: CGFloat = 8
        static let scrollStackSpacing: CGFloat = 22
        static let logoSize: CGFloat = 24
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
        static let estimatedRowHeight: CGFloat = 44
        static let padding = NSDirectionalEdgeInsets(
            top: 22,
            leading: 16,
            bottom: -16,
            trailing: -16
        )
        static let contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
    }

    private var logoSizeScaled: CGFloat {
        return UIFontMetrics.default.scaledValue(for: UX.logoSize)
    }

    private lazy var headerView: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = UX.headerStackSpacing
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = String(
            format: .Microsurvey.Prompt.LogoImageA11yLabel,
            AppName.shortName.rawValue
        )
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo
    }

    private var headerLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.numberOfLines = 0
        label.text = .Microsurvey.Survey.HeaderLabel
        label.accessibilityTraits.insert(.header)
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.accessibilityLabel = .Microsurvey.Survey.CloseButtonAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Survey.closeButton
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
    }

    private lazy var scrollView: UIScrollView = .build()

    private lazy var scrollContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.scrollStackSpacing
    }

    private lazy var containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var tableView: MicrosurveyTableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.delegate = self
        tableView.dataSource = self

        tableView.estimatedRowHeight = UX.estimatedRowHeight
        tableView.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var submitButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapSubmit), for: .touchUpInside)
        button.isEnabled = false
    }

    private lazy var privacyPolicyButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapPrivacyPolicy), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.accessibilityTraits.insert(.link)
        button.accessibilityTraits.remove(.button)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private lazy var confirmationView: MicrosurveyConfirmationView = .build()

    private var logoWidthConstraint: NSLayoutConstraint?
    private var logoHeightConstraint: NSLayoutConstraint?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: MicrosurveyModel, windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        microsurveyState = MicrosurveyState(windowUUID: windowUUID)
        self.model = model
        super.init(nibName: nil, bundle: nil)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        subscribeToRedux()
        configureUI()
        setupLayout()
    }

    // MARK: Redux
    func newState(state: MicrosurveyState) {
        microsurveyState = state
        if microsurveyState.shouldDismiss {
            coordinator?.dismissFlow()
        } else if microsurveyState.showPrivacy {
            coordinator?.showPrivacy(with: model.utmContent)
        }
    }

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .microsurvey)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return MicrosurveyState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .microsurvey)
        store.dispatch(action)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: String.Microsurvey.Survey.SurveyA11yLabel)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(
            MicrosurveyAction(surveyId: model.id, windowUUID: windowUUID, actionType: MicrosurveyActionType.surveyDidAppear)
        )
    }

    deinit {
        unsubscribeFromRedux()
        tableView.removeFromSuperview()
    }

    private func configureUI() {
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .Microsurvey.Survey.SubmitSurveyButton,
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Survey.submitButton
        )
        submitButton.configure(viewModel: viewModel)

        let privacyPolicyButtonViewModel = LinkButtonViewModel(
            title: .Microsurvey.Survey.PrivacyPolicyLinkButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Survey.privacyPolicyLink,
            font: FXFontStyles.Regular.caption2.scaledFont(),
            contentInsets: UX.contentInsets,
            contentHorizontalAlignment: .center
        )
        privacyPolicyButton.configure(viewModel: privacyPolicyButtonViewModel)
    }

    private func setupLayout() {
        headerView.addArrangedSubview(logoImage)
        headerView.addArrangedSubview(headerLabel)
        headerView.addArrangedSubview(closeButton)

        containerView.addSubviews(tableView)

        scrollContainer.addArrangedSubview(containerView)
        scrollContainer.addArrangedSubview(submitButton)
        scrollContainer.addArrangedSubview(privacyPolicyButton)
        scrollContainer.accessibilityElements = [containerView, submitButton, privacyPolicyButton]

        scrollView.addSubview(scrollContainer)

        view.addSubviews(headerView, scrollView)

        logoWidthConstraint = logoImage.widthAnchor.constraint(equalToConstant: logoSizeScaled)
        logoHeightConstraint = logoImage.heightAnchor.constraint(equalToConstant: logoSizeScaled)
        logoWidthConstraint?.isActive = true
        logoHeightConstraint?.isActive = true

        NSLayoutConstraint.activate(
            [
                headerLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor),

                headerView.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: UX.padding.top
                ),
                headerView.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                    constant: UX.padding.leading
                ),
                headerView.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: UX.padding.trailing
                ),

                scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -UX.padding.bottom),

                scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                scrollContainer.topAnchor.constraint(
                    equalTo: scrollView.topAnchor),
                scrollContainer.leadingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                    constant: UX.padding.leading
                ),
                scrollContainer.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: UX.padding.trailing
                ),
                scrollContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

                tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ]
        )
    }

    private func adjustIconSize() {
        logoWidthConstraint?.constant = logoSizeScaled
        logoHeightConstraint?.constant = logoSizeScaled
    }

    // MARK: ThemeApplicable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3

        headerLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        tableView.backgroundColor = theme.colors.layer2
        tableView.layer.borderColor = theme.colors.borderPrimary.cgColor
        tableView.separatorColor = theme.colors.borderPrimary

        containerView.backgroundColor = theme.colors.layer2
        containerView.layer.borderColor = theme.colors.borderPrimary.cgColor
        containerView.layer.borderWidth = UX.borderWidth

        submitButton.applyTheme(theme: theme)
        privacyPolicyButton.applyTheme(theme: theme)
    }

    // MARK: Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustIconSize()
        default: break
        }
    }

    @objc
    private func didTapSubmit() {
        sendTelemetry()
        showConfirmationPage()
    }

    private func sendTelemetry() {
        store.dispatch(
            MicrosurveyAction(
                surveyId: model.id,
                userSelection: selectedOption,
                windowUUID: windowUUID,
                actionType: MicrosurveyActionType.submitSurvey
            )
        )
    }

    private func showConfirmationPage() {
        headerLabel.text = .Microsurvey.Survey.ConfirmationPage.HeaderLabel
        tableView.removeFromSuperview()
        submitButton.removeFromSuperview()
        containerView.addSubview(confirmationView)
        scrollContainer.accessibilityElements = [containerView, privacyPolicyButton]
        NSLayoutConstraint.activate(
            [
                confirmationView.topAnchor.constraint(equalTo: containerView.topAnchor),
                confirmationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                confirmationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                confirmationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ]
        )
        confirmationView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        store.dispatch(
            MicrosurveyAction(
                surveyId: model.id,
                windowUUID: windowUUID,
                actionType: MicrosurveyActionType.confirmationViewed
            )
        )
    }

    @objc
    private func didTapClose() {
        store.dispatch(
            MicrosurveyAction(
                surveyId: model.id,
                windowUUID: windowUUID,
                actionType: MicrosurveyActionType.closeSurvey
            )
        )
    }

    @objc
    private func didTapPrivacyPolicy() {
        store.dispatch(
            MicrosurveyAction(
                surveyId: model.id,
                windowUUID: windowUUID,
                actionType: MicrosurveyActionType.tapPrivacyNotice
            )
        )
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.surveyOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MicrosurveyTableViewCell.cellIdentifier,
            for: indexPath
        ) as? MicrosurveyTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(model.surveyOptions[indexPath.row])
        cell.setA11yValue(for: indexPath.row, outOf: tableView.numberOfRows(inSection: .zero))
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: MicrosurveyTableHeaderView.cellIdentifier
        ) as? MicrosurveyTableHeaderView else {
            return nil
        }
        headerView.configure(model.surveyQuestion, icon: model.icon)
        headerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        submitButton.isEnabled = true
        let selectedCell = tableView.cellForRow(at: indexPath) as? MicrosurveyTableViewCell
        if selectedCell?.checked == false {
            (tableView.cellForRow(at: indexPath) as? MicrosurveyTableViewCell)?.checked.toggle()
            selectedOption = selectedCell?.title
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? MicrosurveyTableViewCell)?.checked = false
    }
}
