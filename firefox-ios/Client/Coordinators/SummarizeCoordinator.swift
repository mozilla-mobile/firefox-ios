// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
import Common
import ComponentLibrary
import UIKit
import Shared

/// Conforming types can show and hide the browser content together with its toolbars.
protocol BrowserContentHiding: AnyObject {
    func showBrowserContent()

    func hideBrowserContent()
}

class SummarizeCoordinator: BaseCoordinator {
    private let browserSnapshot: UIImage
    private let browserSnapshotTopOffset: CGFloat
    private weak var browserContentHiding: BrowserContentHiding?
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let windowUUID: WindowUUID
    private let prefs: Prefs
    private let onRequestOpenURL: ((URL?) -> Void)?

    init(
        browserSnapshot: UIImage,
        browserSnapshotTopOffset: CGFloat,
        browserContentHiding: BrowserContentHiding,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        prefs: Prefs,
        windowUUID: WindowUUID,
        router: Router,
        onRequestOpenURL: ((URL?) -> Void)?
    ) {
        self.browserSnapshot = browserSnapshot
        self.browserSnapshotTopOffset = browserSnapshotTopOffset
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.browserContentHiding = browserContentHiding
        self.windowUUID = windowUUID
        self.prefs = prefs
        self.onRequestOpenURL = onRequestOpenURL
        super.init(router: router)
    }

    func start() {
        if prefs.boolForKey(PrefsKeys.Summarizer.didAgreeToSTerms) ?? false {
            showSummarizeViewController()
        } else {
            showToSAlert()
        }
    }

    private func showSummarizeViewController() {
        let model = SummarizeViewModel(
            loadingLabel: .Summarizer.LoadingLabel,
            loadingA11yLabel: .Summarizer.LoadingAccessibilityLabel,
            loadingA11yId: AccessibilityIdentifiers.Summarizer.loadingLabel,
            summarizeTextViewA11yLabel: .Summarizer.SummaryTextAccessibilityLabel,
            summarizeTextViewA11yId: AccessibilityIdentifiers.Summarizer.summaryTextView,
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .Summarizer.CloseButtonAccessibilityLabel,
                a11yIdentifier: AccessibilityIdentifiers.Summarizer.closeSummaryButton
            ),
            tabSnapshot: browserSnapshot,
            tabSnapshotTopOffset: browserSnapshotTopOffset
        ) { [weak self] in
            guard let self else { return }
            parentCoordinatorDelegate?.didFinish(from: self)
            browserContentHiding?.showBrowserContent()
        } onShouldShowTabSnapshot: { [weak self] in
            self?.browserContentHiding?.hideBrowserContent()
        }

        let controller = SummarizeController(windowUUID: windowUUID, viewModel: model)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overFullScreen
        router.present(controller, animated: true)
    }

    private func showToSAlert() {
        let tosViewModel = ToSBottomSheetViewModel(
            titleLabel: .Summarizer.ToSAlertTitleLabel,
            descriptionLabel: .Summarizer.ToSAlertMessageLabel,
            linkButtonLabel: .Summarizer.ToSAlertLinkButtonLabel,
            linkButtonURL: URL(string: "https://www.mozilla.com"),
            allowButtonTitle: .Summarizer.ToSAlertAllowButtonLabel,
            allowButtonA11yId: AccessibilityIdentifiers.Summarizer.tosAllowButton,
            cancelButtonTitle: .Summarizer.ToSAlertCancelButtonLabel,
            cancelButtonA11yId: AccessibilityIdentifiers.Summarizer.tosCancelButton) { [weak self] url in
            self?.onRequestOpenURL?(url)
            self?.dismissCoordinator()
        } onAllowButtonPressed: { [weak self] in
            self?.prefs.setBool(true, forKey: PrefsKeys.Summarizer.didAgreeToSTerms)
            self?.showSummarizeViewController()
        }
        let tosController = BottomSheetViewController(
            viewModel: BottomSheetViewModel(
                animationTransitionDuration: 0.25,
                shouldDismissForTapOutside: true,
                closeButtonA11yLabel: .Summarizer.ToSCancelButtonAccessibilityLabel,
                closeButtonA11yIdentifier: AccessibilityIdentifiers.Summarizer.tosCancelButton
            ),
            childViewController: ToSBottomSheetViewController(viewModel: tosViewModel, windowUUID: windowUUID),
            usingDimmedBackground: true,
            windowUUID: windowUUID
        )
        router.present(tosController, animated: true)
    }

    private func dismissCoordinator() {
        parentCoordinatorDelegate?.didFinish(from: self)
    }
}
