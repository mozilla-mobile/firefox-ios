// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class PaddedSwitch: UIView, ThemeApplicable {
    struct UX {
        static let padding: CGFloat = 8
    }

    private lazy var control: ThemedSwitch = .build { _ in }
    private var viewModel: PaddedSwitchViewModel?

    public init() {
        super.init(frame: .zero)

        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        addSubview(control)
        frame.size = CGSize(width: control.frame.width + UX.padding,
                            height: control.frame.height)
        control.frame.origin = CGPoint(x: UX.padding, y: 0)

        NSLayoutConstraint.activate([
            control.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            control.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            control.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            control.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(with viewModel: PaddedSwitchViewModel) {
        self.viewModel = viewModel
        control.applyTheme(theme: viewModel.theme)
        control.isEnabled = viewModel.isEnabled
        control.isOn = viewModel.isOn
        control.accessibilityIdentifier = viewModel.a11yIdentifier
    }

    @objc
    func switchValueChanged(_ toggle: UISwitch) {
        viewModel?.valueChangedClosure?()
    }

    public func applyTheme(theme: Theme) {}
}
