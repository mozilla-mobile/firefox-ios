// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import QuickAnswersKit
import Shared
import UIKit

/// Hosts the Quick Answers return pill over the browser, owning its position and visibility.
/// The pill sizes itself, so only its position is constrained.
@MainActor
final class QuickAnswersReturnPillPresenter {
    struct LayoutContext: Equatable {
        let isMinimized: Bool
        let isBottomSearchBar: Bool
        /// The location view frame in the host view's coordinates.
        let locationViewFrame: CGRect?
    }

    private enum Placement: Equatable {
        case aboveAnchor
        case bottom(hasSafeAreaBottom: Bool)
    }

    private enum UX {
        static let fadeDuration: TimeInterval = 0.2
        static let bottomSpacing: CGFloat = 8
        static let sideInset: CGFloat = 16
        static let minimizedLocationSpacing: CGFloat = 10
        static let minimizedBottomInset: CGFloat = 8
    }

    private weak var hostView: UIView?
    private weak var anchorView: UIView?
    private let overlayState: OverlayStateProtocol
    private var pill: QuickAnswersReturnPillView?
    private var placement: Placement?
    private var constraints: [NSLayoutConstraint] = []

    /// - Parameters:
    ///   - hostView: The view the pill is added to.
    ///   - anchorView: The view the expanded pill sits above, whose top already follows the bar position and keyboard.
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

        guard self.pill == nil, let hostView else { return }
        self.pill = pill
        hostView.addSubview(pill)
        apply(.aboveAnchor, to: pill)
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
        guard let pill, let hostView else { return }
        let newPlacement = placement(for: context, in: hostView)
        if newPlacement != placement {
            apply(newPlacement, to: pill)
        }
        pill.setMinimized(
            context.isMinimized,
            restingOffset: restingOffset(for: context, in: hostView),
            animated: animated
        )
    }

    func updateVisibility() {
        guard let pill, let hostView else { return }
        let isVisible = !overlayState.inOverlayMode && !hostView.subviews.contains { $0 is Toast }
        pill.isUserInteractionEnabled = isVisible
        UIView.animate(withDuration: UX.fadeDuration) {
            pill.alpha = isVisible ? 1 : 0
        }
    }

    func bringPillToFront() {
        guard let pill else { return }
        hostView?.bringSubviewToFront(pill)
    }

    func applyTheme(_ theme: Theme) {
        pill?.applyTheme(theme: theme)
    }

    /// With a bottom address bar the minimized pill keeps its expanded constraints and is offset next to the
    /// location view. Otherwise it sits at the bottom of the screen.
    private func placement(for context: LayoutContext, in hostView: UIView) -> Placement {
        guard context.isMinimized, !trailsLocationView(context) else { return .aboveAnchor }
        return .bottom(hasSafeAreaBottom: hostView.safeAreaInsets.bottom > 0)
    }

    private func trailsLocationView(_ context: LayoutContext) -> Bool {
        return context.isMinimized && context.isBottomSearchBar && context.locationViewFrame != nil
    }

    /// The offset from the minimized pill's constrained center, above the anchor, to the trailing side of the
    /// location view.
    private func restingOffset(for context: LayoutContext, in hostView: UIView) -> CGPoint {
        guard trailsLocationView(context), let frame = context.locationViewFrame, let anchorView else { return .zero }
        let halfSize = QuickAnswersReturnPillView.minimizedSize / 2
        let anchorTop = anchorView.convert(anchorView.bounds, to: hostView).minY
        let constrainedCenter = CGPoint(
            x: hostView.safeAreaLayoutGuide.layoutFrame.midX,
            y: anchorTop - UX.bottomSpacing - halfSize
        )
        let targetCenter = CGPoint(x: frame.maxX + UX.minimizedLocationSpacing + halfSize, y: frame.midY)
        return CGPoint(x: targetCenter.x - constrainedCenter.x, y: targetCenter.y - constrainedCenter.y)
    }

    private func apply(_ newPlacement: Placement, to pill: UIView) {
        NSLayoutConstraint.deactivate(constraints)
        constraints = makeConstraints(for: newPlacement, pill: pill) ?? []
        NSLayoutConstraint.activate(constraints)
        placement = newPlacement
    }

    private func makeConstraints(for placement: Placement, pill: UIView) -> [NSLayoutConstraint]? {
        guard let hostView, let anchorView else { return nil }
        let safeArea = hostView.safeAreaLayoutGuide
        switch placement {
        case .aboveAnchor:
            return [
                pill.bottomAnchor.constraint(equalTo: anchorView.topAnchor, constant: -UX.bottomSpacing),
                pill.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                pill.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: UX.sideInset)
            ]
        case .bottom(let hasSafeAreaBottom):
            return [
                pill.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                pill.bottomAnchor.constraint(
                    equalTo: safeArea.bottomAnchor,
                    constant: hasSafeAreaBottom ? 0 : -UX.minimizedBottomInset
                )
            ]
        }
    }
}
