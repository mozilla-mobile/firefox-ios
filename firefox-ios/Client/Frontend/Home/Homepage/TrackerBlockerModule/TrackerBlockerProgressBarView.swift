// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A simple track + gradient-fill progress bar used in each tracker category row.
///
/// The fill ratio is computed by the caller (see `TrackerBlockerSheetState.fillRatio(for:)`) — this view only
/// clamps it to `0...1` and sizes the fill accordingly.
final class TrackerBlockerProgressBarView: UIView, ThemeApplicable {
    private struct UX {
        static let height: CGFloat = 6
    }

    private let trackView: UIView = .build { view in
        view.clipsToBounds = true
    }

    private let fillView: TrackerBlockerGradientView = .build { view in
        view.clipsToBounds = true
    }

    private var fillWidthConstraint: NSLayoutConstraint?
    private var fillRatio: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackView.layer.cornerRadius = UX.height / 2
        fillView.layer.cornerRadius = UX.height / 2
    }

    private func setupLayout() {
        addSubview(trackView)
        trackView.addSubview(fillView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: UX.height),

            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor)
        ])

        updateFillConstraint()
    }

    func setFillRatio(_ ratio: CGFloat) {
        fillRatio = max(0, min(1, ratio))
        updateFillConstraint()
    }

    private func updateFillConstraint() {
        fillWidthConstraint?.isActive = false
        // Multipliers are immutable, so recreate the constraint whenever the ratio changes.
        let constraint = fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: fillRatio)
        constraint.isActive = true
        fillWidthConstraint = constraint
    }

    func applyTheme(theme: Theme) {
        trackView.backgroundColor = theme.colors.layer3
        // TODO: FXIOS-XXXXX - Replace with a real progress gradient token once defined in the design system.
        let gradient = theme.type.getInterfaceStyle() == .dark
            ? theme.colors.gradientPrivacy
            : Gradient(colors: [UIColor(rgb: 0x764edd), UIColor(rgb: 0xb393ff)])
        fillView.configure(colors: gradient.colors,
                           startPoint: CGPoint(x: 0, y: 0.5),
                           endPoint: CGPoint(x: 1, y: 0.5))
    }
}
