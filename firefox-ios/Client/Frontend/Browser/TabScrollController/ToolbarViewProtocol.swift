// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit

@MainActor
protocol ToolbarViewProtocol: AnyObject {
    var header: BaseAlphaStackView { get }
    var topBlurView: UIVisualEffectView { get }
    var bottomContainer: BaseAlphaStackView { get }
    var bottomBlurView: UIVisualEffectView { get }
    var overKeyboardContainer: BaseAlphaStackView { get }
    var isBottomSearchBar: Bool { get }
    var headerTopConstraint: Constraint? { get }
    var bottomContainerConstraint: ConstraintReference? { get }
    var overKeyboardContainerConstraint: ConstraintReference? { get }
}

struct ToolbarContext {
    var overKeyboardContainerHeight: CGFloat
    var bottomContainerHeight: CGFloat
    var headerHeight: CGFloat
}

@MainActor
final class ToolbarAnimator {
    protocol Delegate: AnyObject {
        @MainActor
        func dispatchScrollAlphaChange(alpha: CGFloat)
    }

    struct UX {
        static let transitionDuration: TimeInterval = 0.2
        static let topToolbarDuration: TimeInterval = 0.3
        static let bottomToolbarDuration: TimeInterval = 0.4
    }

    weak var view: ToolbarViewProtocol?
    weak var delegate: ToolbarAnimator.Delegate?
    private var context: ToolbarContext

    init(context: ToolbarContext) {
        self.context = context
    }

    /// Animates the toolbar's position during scroll-based transitions between expanded and collapsed states.
    /// It’s typically called by the scroll handler as the user scrolls the page, to visually collapse
    /// or expand the toolbar according to the scroll direction and progress.
    /// - Parameters:
    ///   - progress: The current scroll progress, expressed as a vertical offset value.
    ///                Positive values indicate upward scrolling (collapsing), while negative values
    ///                indicate downward scrolling (expanding).
    ///   - state: The target toolbar display state, either `.collapsed` or `.expanded`.
    func updateToolbarTransition(progress: CGFloat, towards state: TabScrollHandler.ToolbarDisplayState) {
        guard let view else { return }

        let isCollapsing = (state == .collapsed)
        let clampProgress = isCollapsing ? max(0, progress) : min(0, progress)

        UIView.animate(withDuration: UX.transitionDuration, delay: 0, options: [.curveEaseOut]) {
            if view.isBottomSearchBar {
                let translationY = isCollapsing ? clampProgress : 0
                let transform = CGAffineTransform(translationX: 0, y: translationY)
                view.bottomContainer.transform = transform
                view.overKeyboardContainer.transform = transform
                view.bottomBlurView.transform = transform
            } else {
                let transform = isCollapsing
                    ? CGAffineTransform(translationX: 0, y: -clampProgress)
                    : .identity
                view.header.transform = transform
                view.topBlurView.transform = transform
            }
        }
    }

    func showToolbar() {
        guard let view else { return }

        if !view.isBottomSearchBar {
            updateTopToolbar(alpha: 1)
        }

        updateBottomToolbar(alpha: 1)
    }

    func hideToolbar() {
        guard let view else { return }

        if !view.isBottomSearchBar {
            updateTopToolbar(alpha: 0)
        }

        updateBottomToolbar(alpha: 0)
    }

    func updateToolbarContext(_ updateContext: ToolbarContext) {
        context = updateContext
    }

    // MARK: - Helper private functions

    private func updateTopToolbar(alpha: CGFloat) {
        guard let view, UIAccessibility.isReduceMotionEnabled else {
            animateTopToolbar(alpha: alpha)
            return
        }

        let topOffset = alpha == 1 ? context.headerHeight : 0
        updateTopToolbarConstraints(topContainerOffset: topOffset)
        view.header.updateAlphaForSubviews(alpha)
        delegate?.dispatchScrollAlphaChange(alpha: alpha)
    }

    private func updateTopToolbarConstraints(topContainerOffset: CGFloat) {
        guard let view else { return }

        view.headerTopConstraint?.update(offset: topContainerOffset)
        view.header.superview?.setNeedsLayout()
    }

    private func updateBottomToolbar(alpha: CGFloat) {
        guard UIAccessibility.isReduceMotionEnabled else {
            animateBottomToolbar(alpha: alpha)
            return
        }

        let overKeyboardContainerOffset = alpha == 1 ? 0 : context.overKeyboardContainerHeight
        let bottomContainerOffset = alpha == 1 ? 0 : context.bottomContainerHeight
        updateBottomToolbarConstraints(bottomContainerOffset: bottomContainerOffset,
                                       overKeyboardContainerOffset: overKeyboardContainerOffset)

        delegate?.dispatchScrollAlphaChange(alpha: alpha)
    }

    private func updateBottomToolbarConstraints(bottomContainerOffset: CGFloat,
                                                overKeyboardContainerOffset: CGFloat) {
        guard let view else { return }

        view.overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
        view.bottomContainerConstraint?.update(offset: bottomContainerOffset)
        // Both view shared the same parent so layoutIfNeeded is called only once
        view.overKeyboardContainer.superview?.layoutIfNeeded()
    }

    private func animateTopToolbar(alpha: CGFloat) {
        guard let view else { return }

        let isShowing = alpha == 1
        let headerOffset = isShowing ? 0 : context.headerHeight
        UIView.animate(withDuration: UX.topToolbarDuration,
                       delay: 0,
                       options: [.curveEaseOut]) {
            if !isShowing {
                view.header.transform = .identity.translatedBy(x: 0, y: headerOffset)
                view.topBlurView.transform = .identity.translatedBy(x: 0, y: headerOffset)
            } else {
                view.header.transform = .identity
                view.topBlurView.transform = .identity
            }
        }
        delegate?.dispatchScrollAlphaChange(alpha: alpha)
   }

    private func animateBottomToolbar(alpha: CGFloat) {
        guard let view else { return }

        let isShowing = alpha == 1
        let bottomOffset = isShowing ? 0 :  context.bottomContainerHeight
        let overkeyboardOffset = isShowing ? 0 : context.overKeyboardContainerHeight
        UIView.animate(withDuration: UX.bottomToolbarDuration,
                       delay: 0,
                       options: [.curveEaseOut]) {
            if !isShowing {
                view.bottomContainer.transform = .identity.translatedBy(x: 0, y: bottomOffset)
                view.overKeyboardContainer.transform = .identity.translatedBy(x: 0, y: overkeyboardOffset)
                view.bottomBlurView.transform = .identity.translatedBy(x: 0, y: overkeyboardOffset)
            } else {
                view.bottomContainer.transform = .identity
                view.overKeyboardContainer.transform = .identity
                view.bottomBlurView.transform = .identity
            }
            self.updateBottomToolbarConstraints(bottomContainerOffset: bottomOffset,
                                                overKeyboardContainerOffset: overkeyboardOffset)
        }

        self.delegate?.dispatchScrollAlphaChange(alpha: alpha)
   }
}
