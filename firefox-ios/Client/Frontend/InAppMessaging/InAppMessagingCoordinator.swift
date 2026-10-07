// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

protocol InAppMessagingCoordinatorDelegate: AnyObject {
    func inAppMessagingDidRequestOpenURL(_ url: URL)
    func inAppMessagingDidRequestDeepLink(_ deepLink: String)
}

final class InAppMessagingCoordinator {
    private let manager: InAppMessagingManagerProtocol
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let logger: Logger

    weak var delegate: InAppMessagingCoordinatorDelegate?
    private weak var presentingViewController: UIViewController?
    private var activeBanner: InAppBannerView?

    init(
        manager: InAppMessagingManagerProtocol,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.manager = manager
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.logger = logger
    }

    func start(from viewController: UIViewController) {
        presentingViewController = viewController
        Task {
            await manager.fetchMessages()
            await MainActor.run {
                showNextEligibleMessages()
            }
        }
    }

    private func showNextEligibleMessages() {
        if let bannerMessage = manager.nextMessage(for: .banner) {
            showBanner(bannerMessage)
        }

        if let modalMessage = manager.nextMessage(for: .modal) {
            showModal(modalMessage)
        }

        if let webviewMessage = manager.nextMessage(for: .webview) {
            showWebViewSheet(webviewMessage)
        }
    }

    func nextNewTabCardMessage() -> InAppMessage? {
        return manager.nextMessage(for: .newTabCard)
    }

    // MARK: - Banner

    private func showBanner(_ message: InAppMessage) {
        guard let parentView = presentingViewController?.view else { return }

        let banner = InAppBannerView(message: message)
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false

        let theme = themeManager.getCurrentTheme(for: windowUUID)
        banner.applyTheme(theme: theme)

        parentView.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16),
            banner.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])

        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: -20)
        UIView.animate(withDuration: 0.3) {
            banner.alpha = 1
            banner.transform = .identity
        }

        activeBanner = banner
        manager.recordImpression(for: message.id)
    }

    private func dismissBanner(messageID: String) {
        guard let banner = activeBanner else { return }
        manager.recordDismissal(for: messageID)

        UIView.animate(
            withDuration: 0.2,
            animations: {
                banner.alpha = 0
                banner.transform = CGAffineTransform(translationX: 0, y: -20)
            },
            completion: { _ in
                banner.removeFromSuperview()
            }
        )
        activeBanner = nil
    }

    // MARK: - Modal

    private func showModal(_ message: InAppMessage) {
        let modalVC = InAppModalViewController(
            message: message,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        modalVC.delegate = self
        presentingViewController?.present(modalVC, animated: true)
        manager.recordImpression(for: message.id)
    }

    // MARK: - WebView Sheet

    private func showWebViewSheet(_ message: InAppMessage) {
        let sheetVC = InAppWebViewSheetViewController(
            message: message,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        sheetVC.delegate = self

        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = false
        }

        presentingViewController?.present(sheetVC, animated: true)
        manager.recordImpression(for: message.id)
    }

    // MARK: - CTA Handling

    private func handleCTAAction(_ action: InAppMessage.CTAAction?) {
        guard let action else { return }

        switch action.type {
        case .openURL:
            if let url = URL(string: action.value) {
                delegate?.inAppMessagingDidRequestOpenURL(url)
            }
        case .deepLink:
            delegate?.inAppMessagingDidRequestDeepLink(action.value)
        case .dismiss:
            break
        }
    }
}

extension InAppMessagingCoordinator: InAppBannerDelegate {
    func inAppBannerDidTapCTA(_ banner: InAppBannerView, action: InAppMessage.CTAAction?) {
        dismissBanner(messageID: banner.messageID)
        handleCTAAction(action)
    }

    func inAppBannerDidDismiss(_ banner: InAppBannerView) {
        dismissBanner(messageID: banner.messageID)
    }
}

extension InAppMessagingCoordinator: InAppModalDelegate {
    func inAppModalDidTapCTA(_ modal: InAppModalViewController, action: InAppMessage.CTAAction?) {
        modal.dismiss(animated: true) { [weak self] in
            self?.handleCTAAction(action)
        }
    }

    func inAppModalDidDismiss(_ modal: InAppModalViewController) {
        manager.recordDismissal(for: modal.message.id)
        modal.dismiss(animated: true)
    }
}

extension InAppMessagingCoordinator: InAppWebViewSheetDelegate {
    func inAppWebViewSheetDidDismiss(_ sheet: InAppWebViewSheetViewController) {
        manager.recordDismissal(for: sheet.message.id)
        sheet.dismiss(animated: true)
    }
}
