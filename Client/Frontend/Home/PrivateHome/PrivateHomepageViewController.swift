// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit
import Shared

// Delegate for coordinator to be able to handle navigation
protocol PrivateHomepageDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(with url: URL, isPrivate: Bool, selectNewTab: Bool)
}

// Displays the view for the private homepage when users create a new tab in private browsing
final class PrivateHomepageViewController: UIViewController, ContentContainable, Themeable {
    enum UX {
        static let scrollContainerStackSpacing: CGFloat = 24
        static let defaultScrollContainerPadding: CGFloat = 16
        private static let iPadScrollContainerPadding: CGFloat = 164

        static var scrollContainerPadding: CGFloat {
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            return isiPad ? UX.iPadScrollContainerPadding : UX.defaultScrollContainerPadding
        }
    }

    // MARK: ContentContainable Variables
    var contentType: ContentType = .privateHomepage

    // MARK: Theming Variables
    var themeManager: Common.ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: Common.NotificationProtocol

    var parentCoordinator: PrivateHomepageDelegate?

    private let overlayManager: OverlayModeManager
    private let logger: Logger

    // MARK: UI Elements
    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0, 0.5, 1]
        return gradient
    }()

    private let scrollView: UIScrollView = .build()

    private lazy var scrollContainer: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.scrollContainerStackSpacing
    }

    private lazy var privateMessageCardCell: PrivateMessageCardCell = {
        let messageCard = PrivateMessageCardCell()
        let messageCardModel = PrivateMessageCardCell.PrivateMessageCard(
            title: .FirefoxHomepage.FeltPrivacyUI.Title,
            body: String(format: .FirefoxHomepage.FeltPrivacyUI.Body, AppName.shortName.rawValue),
            link: .FirefoxHomepage.FeltPrivacyUI.Link
        )
        messageCard.configure(with: messageCardModel, and: themeManager.currentTheme)
        messageCard.privateBrowsingLinkTapped = learnMore
        return messageCard
    }()

    private lazy var logoHeaderCell: HomeLogoHeaderCell = {
        let logoHeader = HomeLogoHeaderCell()
        logoHeader.applyTheme(theme: themeManager.currentTheme)
        return logoHeader
    }()

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         overlayManager: OverlayModeManager
    ) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.overlayManager = overlayManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        setupDismissKeyboard()

        listenForThemeChange(view)
        applyTheme()
    }

    private func setupLayout() {
        scrollContainer.addArrangedSubview(logoHeaderCell.contentView)
        scrollContainer.addArrangedSubview(privateMessageCardCell)
        scrollContainer.accessibilityElements = [logoHeaderCell.contentView, privateMessageCardCell]

        view.layer.addSublayer(gradient)
        view.addSubview(scrollView)
        scrollView.addSubview(scrollContainer)

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollContainer.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor,
                                                 constant: UX.defaultScrollContainerPadding),
            scrollContainer.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor,
                                                    constant: -UX.defaultScrollContainerPadding),
            scrollContainer.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor,
                                                     constant: UX.scrollContainerPadding),
            scrollContainer.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor,
                                                      constant: -UX.scrollContainerPadding),

            scrollContainer.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor,
                                                   constant: -UX.scrollContainerPadding * 2),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = view.bounds
    }

    func applyTheme() {
        // TODO: Felt Privay - Theming System should be handled by Redux 
        // https://mozilla-hub.atlassian.net/browse/FXIOS-7879
        themeManager.changeCurrentTheme(.privateMode)
        let theme = themeManager.currentTheme
        gradient.colors = theme.colors.layerHomepage.cgColors
        logoHeaderCell.applyTheme(theme: theme)
    }

    private func learnMore() {
        guard let privateBrowsingURL = SupportUtils.URLForPrivateBrowsingLearnMore else {
            self.logger.log("Failed to retrieve URL from SupportUtils.URLForPrivateBrowsingLearnMore",
                            level: .debug,
                            category: .homepage)
            return
        }
        parentCoordinator?.homePanelDidRequestToOpenInNewTab(
            with: privateBrowsingURL,
            isPrivate: true,
            selectNewTab: true
        )
    }

    private func setupDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func dismissKeyboard() {
        overlayManager.finishEditing(shouldCancelLoading: false)
    }
}
