// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

@MainActor
protocol AlphaDimmable {
    func updateAlphaForSubviews(_ alpha: CGFloat)
}

class BaseAlphaStackView: UIStackView, AlphaDimmable, ThemeApplicable {
    var isClearBackground = false
    var isSpacerClearBackground = false
    lazy var toolbarHelper: ToolbarHelperInterface = ToolbarHelper()

    /// Arranged subview that collapses while the toolbars are minimized on scroll.
    weak var scrollCollapsibleView: UIView? {
        didSet {
            guard oldValue !== scrollCollapsibleView else { return }
            oldValue?.isHidden = false
            oldValue?.alpha = 1
        }
    }

    /// Height `scrollCollapsibleView` currently takes up in the stack.
    var scrollCollapsibleHeight: CGFloat {
        guard let scrollCollapsibleView, !scrollCollapsibleView.isHidden else { return 0 }
        return scrollCollapsibleView.frame.height
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupStyle()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        for subview in arrangedSubviews {
            guard let alphaView = subview as? AlphaDimmable else { continue }
            alphaView.updateAlphaForSubviews(alpha)
        }
        updateScrollCollapsibleView(isCollapsed: alpha.isZero)
    }

    /// Hides or shows `scrollCollapsibleView`. Call it inside an animation block to animate the collapse.
    func updateScrollCollapsibleView(isCollapsed: Bool) {
        guard let scrollCollapsibleView, scrollCollapsibleView.isHidden != isCollapsed else { return }
        scrollCollapsibleView.isHidden = isCollapsed
        scrollCollapsibleView.alpha = isCollapsed ? 0 : 1
        superview?.layoutIfNeeded()
    }

    private func setupStyle() {
        axis = .vertical
        distribution = .fill
        alignment = .fill
    }

    // MARK: - Spacer view

    private var keyboardSpacerHeight: NSLayoutConstraint?
    private var keyboardSpacer: UIView?

    func addKeyboardSpacer(spacerHeight: CGFloat) {
        keyboardSpacer?.removeFromSuperview()
        if keyboardSpacer == nil {
            keyboardSpacer = UIView()
            keyboardSpacer?.accessibilityIdentifier = AccessibilityIdentifiers.Browser.keyboardSpacer
        }
        addArrangedViewToBottom(keyboardSpacer!)
        setKeyboardSpacerHeight(height: spacerHeight)
    }

    func removeKeyboardSpacer() {
        guard let keyboardSpacer = self.keyboardSpacer else { return }
        removeArrangedView(keyboardSpacer)
        keyboardSpacerHeight = nil
        self.keyboardSpacer = nil
    }

    private func setKeyboardSpacerHeight(height: CGFloat) {
        guard let keyboardSpacer = self.keyboardSpacer else { return }
        keyboardSpacer.translatesAutoresizingMaskIntoConstraints = false
        // Remove any existing height constraint on keyboardSpacer
        if let existingHeightConstraint = keyboardSpacer.constraints.first(where: {
            $0.firstAttribute == .height && $0.secondItem == nil
        }) {
            keyboardSpacer.removeConstraint(existingHeightConstraint)
        }

        // Create and add the new height constraint
        let heightConstraint = NSLayoutConstraint(item: keyboardSpacer,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: height)
        keyboardSpacer.addConstraint(heightConstraint)
        keyboardSpacerHeight = heightConstraint
    }

    // MARK: - Spacer view

    private var insetSpacer: UIView?

    func addBottomInsetSpacer(spacerHeight: CGFloat) {
        guard insetSpacer == nil else { return }

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        addArrangedViewToBottom(spacer)
        NSLayoutConstraint.activate([
            spacer.heightAnchor.constraint(equalToConstant: spacerHeight),
            spacer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            spacer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            spacer.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        insetSpacer = spacer
    }

    func moveSpacerToBack() {
        guard let insetSpacer = self.insetSpacer else { return }
        sendSubviewToBack(insetSpacer)
    }

    func removeBottomInsetSpacer() {
        guard let insetSpacer = self.insetSpacer else { return }

        removeArrangedView(insetSpacer)
        self.insetSpacer = nil
    }

    func applyTheme(theme: Theme) {
        let color: UIColor = theme.colors.layerSurfaceLow
        let backgroundAlpha = toolbarHelper.glassEffectAlpha

        backgroundColor = isClearBackground ? .clear : color
        keyboardSpacer?.backgroundColor = isSpacerClearBackground ? .clear : color.withAlphaComponent(backgroundAlpha)
        insetSpacer?.backgroundColor = isSpacerClearBackground ? .clear : color.withAlphaComponent(backgroundAlpha)
    }
}
