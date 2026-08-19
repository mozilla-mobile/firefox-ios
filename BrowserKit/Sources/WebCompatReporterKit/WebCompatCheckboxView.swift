// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A filled circle carrying a checkmark when on, an empty ring when off.
final class WebCompatCheckboxView: UIView {
    private var checkmarkSizeConstraints: [NSLayoutConstraint] = []

    private var scaledSize: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Checkbox.size)
    }

    private var scaledCheckmarkSize: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Checkbox.checkmarkSize)
    }

    private lazy var checkmarkView: UIImageView = .build({ imageView in
        imageView.contentMode = .scaleAspectFit
    }, {
        let image = UIImage(named: StandardImageIdentifiers.Large.checkmark)?.withRenderingMode(.alwaysTemplate)
        return UIImageView(image: image)
    })

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(checkmarkView)
        checkmarkSizeConstraints = [
            checkmarkView.widthAnchor.constraint(equalToConstant: scaledCheckmarkSize),
            checkmarkView.heightAnchor.constraint(equalToConstant: scaledCheckmarkSize)
        ]
        NSLayoutConstraint.activate(checkmarkSizeConstraints + [
            checkmarkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkmarkView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        layer.cornerRadius = scaledSize / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The accessory system frames this view, so `translatesAutoresizingMaskIntoConstraints`
    /// stays at its default `true` and the size has to come from here. Width and height
    /// constraints on `self` would fight the autoresizing constraints UIKit generates.
    override var intrinsicContentSize: CGSize {
        return CGSize(width: scaledSize, height: scaledSize)
    }

    func update(isChecked: Bool, theme: Theme) {
        checkmarkView.isHidden = !isChecked
        checkmarkView.tintColor = theme.colors.textInverted
        backgroundColor = isChecked ? theme.colors.actionPrimary : .clear
        layer.borderWidth = isChecked ? 0 : WebCompatReporterUX.Checkbox.borderWidth
        layer.borderColor = isChecked ? nil : theme.colors.borderPrimary.cgColor
    }

    func applyScaledMetrics() {
        checkmarkSizeConstraints.forEach { $0.constant = scaledCheckmarkSize }
        layer.cornerRadius = scaledSize / 2
        invalidateIntrinsicContentSize()
    }
}
