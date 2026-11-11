// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import QuickAnswersKit
import Shared
import UIKit

@MainActor
final class QuickAnswersReturnPillPresenter {
    struct LayoutContext: Equatable {
        let isMinimized: Bool
        let isBottomSearchBar: Bool
        /// The location view frame in the host view's coordinates.
        let locationViewFrame: CGRect?
    }

    private enum Placement: Equatable {
        case expanded
        case trailingLocationView(CGRect)
        case bottom(isAboveHomeIndicator: Bool)
    }

    private enum UX {
        static let fadeDuration: TimeInterval = 0.2
        static let bottomSpacing: CGFloat = 8
        static let sideInset: CGFloat = 16
        static let minimizedLocationSpacing: CGFloat = 10
        static let minimizedHomeIndicatorOffset: CGFloat = 4
        static let minimizedBottomInset: CGFloat = 8
    }

    private unowned let hostView: UIView
    private unowned let anchorView: UIView
    private let overlayState: OverlayStateProtocol
    private var pill: QuickAnswersReturnPillView?
    private var placement: Placement?
    private var constraints: [NSLayoutConstraint] = []

    /// - Parameters:
    ///   - hostView: The view the pill is added to.
    ///   - anchorView: The view the expanded pill sits above.
    init(hostView: UIView, anchorView: UIView, overlayState: OverlayStateProtocol) {
        self.hostView = hostView
        self.anchorView = anchorView
        self.overlayState = overlayState
    }

    /// An already shown pill is only reconfigured, it keeps the closures it was created with.
    func show(
        question: String,
        theme: Theme,
        onTap: @escaping (Bool) -> Void,
        onSwipeAway: @escaping () -> Void
    ) {
        let pill = pill ?? QuickAnswersReturnPillView(
            accessibilityIdentifier: "",
            onTap: onTap,
            onSwipeAway: { [weak self] in
                onSwipeAway()
                self?.hide()
            }
        )
        pill.configure(
            question: question,
            subtitle: String.QuickAnswers.ReturnPill.Subtitle
        )
        pill.applyTheme(theme: theme)

        guard self.pill == nil else { return }
        self.pill = pill
        hostView.addSubview(pill)
        apply(.expanded, to: pill)
        updateVisibility()
    }

    func hide() {
        guard let pill else { return }
        NSLayoutConstraint.deactivate(constraints)
        constraints = []
        placement = nil
        pill.removeFromSuperview()
        self.pill = nil
    }

    func updateLayout(_ context: LayoutContext, animated: Bool) {
        guard let pill else { return }
        let newPlacement = placement(for: context)
        if newPlacement != placement {
            apply(newPlacement, to: pill)
        }
        pill.setMinimized(context.isMinimized, animated: animated)
    }

    func updateVisibility() {
        guard let pill else { return }
        let isVisible = !overlayState.inOverlayMode && !hostView.subviews.contains { $0 is Toast }
        pill.isUserInteractionEnabled = isVisible
        UIView.animate(withDuration: UX.fadeDuration) {
            pill.alpha = isVisible ? 1 : 0
        }
    }

    func bringPillToFront() {
        guard let pill else { return }
        hostView.bringSubviewToFront(pill)
    }

    func applyTheme(_ theme: Theme) {
        pill?.applyTheme(theme: theme)
    }

    private func placement(for context: LayoutContext) -> Placement {
        if !context.isMinimized {
            return .expanded
        } else if context.isBottomSearchBar, let frame = context.locationViewFrame {
            return .trailingLocationView(frame)
        }
        return .bottom(isAboveHomeIndicator: hostView.safeAreaInsets.bottom > 0)
    }

    private func apply(_ newPlacement: Placement, to pill: UIView) {
        NSLayoutConstraint.deactivate(constraints)
        constraints = makeConstraints(for: newPlacement, pill: pill)
        NSLayoutConstraint.activate(constraints)
        placement = newPlacement
    }

    private func makeConstraints(for placement: Placement, pill: UIView) -> [NSLayoutConstraint] {
        let safeArea = hostView.safeAreaLayoutGuide
        switch placement {
        case .expanded:
            return [
                pill.bottomAnchor.constraint(equalTo: anchorView.topAnchor, constant: -UX.bottomSpacing),
                pill.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                pill.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: UX.sideInset)
            ]
        case .trailingLocationView(let frame):
            return [
                pill.centerYAnchor.constraint(equalTo: hostView.topAnchor, constant: frame.midY),
                pill.leadingAnchor.constraint(equalTo: hostView.leadingAnchor,
                                              constant: frame.maxX + UX.minimizedLocationSpacing)
            ]
        case .bottom(let isAboveHomeIndicator):
            let vertical = isAboveHomeIndicator
                ? pill.centerYAnchor.constraint(equalTo: safeArea.bottomAnchor,
                                                constant: -UX.minimizedHomeIndicatorOffset)
                : pill.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -UX.minimizedBottomInset)
            return [pill.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor), vertical]
        }
    }
}
