// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import TipKit

/// Presents the Quick Answers privacy tip as a popover anchored to the "About your privacy" link,
/// and owns the lifecycle quirks of `TipUIPopoverViewController`.
@MainActor
final class QuickAnswersPrivacyTipPresenter {
    private struct UX {
        /// The natural size of the acorn icon, which TipKit would otherwise scale up.
        static let imageSize = CGSize(width: 24.0, height: 24.0)
    }

    /// TipKit is unavailable before iOS 17, so the link opening this tip has to stay hidden there.
    static var isSupported: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }

    private weak var presenter: UIViewController?
    private let strings: QuickAnswersViewConfiguration.PrivacyBannerStrings
    private weak var popover: UIViewController?
    private var invalidationTask: Task<Void, Never>?

    init(presenter: UIViewController, strings: QuickAnswersViewConfiguration.PrivacyBannerStrings) {
        self.presenter = presenter
        self.strings = strings
    }

    deinit {
        invalidationTask?.cancel()
    }

    func present(from sourceView: UIView, iconColor: UIColor) {
        guard #available(iOS 17.0, *), let presenter else { return }
        let tip = QuickAnswersPrivacyTip(strings: strings, iconColor: iconColor)
        let popover = TipUIPopoverViewController(tip, sourceItem: sourceView)
        popover.imageSize = UX.imageSize
        popover.popoverPresentationController?.permittedArrowDirections = .down
        self.popover = popover
        observeInvalidation(of: tip)
        presenter.present(popover, animated: true)
    }

    /// `TipUIPopoverViewController` only invalidates its tip when the close button is tapped, dismissing
    /// the popover is left to the presenter.
    @available(iOS 17.0, *)
    private func observeInvalidation(of tip: QuickAnswersPrivacyTip) {
        invalidationTask?.cancel()
        invalidationTask = Task { @MainActor [weak self] in
            for await status in tip.statusUpdates {
                guard !Task.isCancelled else { return }
                guard case .invalidated = status else { continue }
                self?.dismiss()
                return
            }
        }
    }

    private func dismiss() {
        guard let presenter, let popover, presenter.presentedViewController === popover else { return }
        presenter.dismiss(animated: true)
        self.popover = nil
    }
}
