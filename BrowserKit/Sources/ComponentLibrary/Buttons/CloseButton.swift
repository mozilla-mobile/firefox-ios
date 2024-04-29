// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class CloseButton: UIButton {
    private var viewModel: CloseButtonViewModel?

    private struct UX {
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let crossCircleImage = StandardImageIdentifiers.ExtraLarge.crossCircleFill
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setImage(UIImage(named: UX.crossCircleImage), for: .normal)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width)
        ])
    }

    public func configure(viewModel: CloseButtonViewModel) {
        self.viewModel = viewModel

        accessibilityIdentifier = viewModel.a11yIdentifier
        accessibilityLabel = viewModel.a11yLabel
    }
}
