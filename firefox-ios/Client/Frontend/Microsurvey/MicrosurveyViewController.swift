// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary

class MicrosurveyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, Themeable {
    // MARK: Themable Variables
    var themeManager: Common.ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: Common.NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }

    private let windowUUID: WindowUUID

    // TODO: FXIOS-9059 / FXIOS-8990 - Replace after Redux implementation + microsurvey surface manager is implemented
    private let surveyOptions: [String] = [
        .Microsurvey.Survey.Options.LikertScaleOption1,
        .Microsurvey.Survey.Options.LikertScaleOption2,
        .Microsurvey.Survey.Options.LikertScaleOption3,
        .Microsurvey.Survey.Options.LikertScaleOption4,
        .Microsurvey.Survey.Options.LikertScaleOption5
    ]

    // MARK: UI Elements
    private struct UX {
        static let headerStackSpacing: CGFloat = 8
        static let scrollStackSpacing: CGFloat = 22
        static let logoSize = CGSize(width: 24, height: 24)
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
        static let estimatedRowHeight: CGFloat = 44
        static let padding = NSDirectionalEdgeInsets(
            top: 22,
            leading: 16,
            bottom: -16,
            trailing: -16
        )
    }

    private lazy var headerView: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.alignment = self.headerLabel.numberOfLines > 1 ? .top : .center
        stack.spacing = UX.headerStackSpacing
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
        // TODO: FXIOS-9028: Add A11y strings
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
    }

    private lazy var privacyPolicyButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapPrivacyPolicy), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.accessibilityTraits.insert(.link)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        self.sheetPresentationController?.prefersGrabberVisible = true
        configureUI()
        setupLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        applyTheme()
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
            contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
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

        scrollView.addSubview(scrollContainer)

        view.addSubviews(headerView, scrollView)

        NSLayoutConstraint.activate(
            [
                logoImage.widthAnchor.constraint(equalToConstant: UX.logoSize.width),
                logoImage.heightAnchor.constraint(equalToConstant: UX.logoSize.height),

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

    func applyTheme() {
        let theme = themeManager.currentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1

        headerLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        tableView.backgroundColor = theme.colors.layer2

        containerView.backgroundColor = theme.colors.layer2
        containerView.layer.borderColor = theme.colors.borderPrimary.cgColor
        containerView.layer.borderWidth = UX.borderWidth

        submitButton.applyTheme(theme: theme)
        privacyPolicyButton.applyTheme(theme: theme)
    }

    @objc
    private func didTapSubmit() {
        // TODO: FXIOS-9072: Add confirmation page
    }

    @objc
    private func didTapClose() {
        // TODO: FXIOS-9059: Redux for Survey close action
    }

    @objc
    private func didTapPrivacyPolicy() {
        // TODO: FXIOS-8976: Privacy policy should open a new tab
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return surveyOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MicrosurveyTableViewCell.cellIdentifier,
            for: indexPath
        ) as? MicrosurveyTableViewCell else {
            return UITableViewCell()
        }
        cell.configureCell(surveyOptions[indexPath.row])
        cell.applyTheme(theme: themeManager.currentTheme(for: windowUUID))
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: MicrosurveyTableHeaderView.cellIdentifier
        ) as? MicrosurveyTableHeaderView else {
            return nil
        }

        headerView.applyTheme(theme: themeManager.currentTheme(for: windowUUID))
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        submitButton.isEnabled = true
        (tableView.cellForRow(at: indexPath) as? MicrosurveyTableViewCell)?.checked.toggle()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? MicrosurveyTableViewCell)?.checked = false
    }
}
