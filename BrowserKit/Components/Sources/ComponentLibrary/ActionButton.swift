// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public class ActionButton: ResizableButton {
    public var foregroundColorNormal: UIColor = .clear {
        didSet {
            configuration?.baseForegroundColor = foregroundColorNormal
        }
    }

    public var backgroundColorNormal: UIColor = .clear {
        didSet {
            configuration?.background.backgroundColor = backgroundColorNormal
        }
    }

    private var viewModel: ActionButtonViewModel?

    @objc
    func touchUpInside(sender: UIButton) {
        viewModel?.touchUpAction?(sender)
    }

    open func configure(viewModel: ActionButtonViewModel) {
        self.viewModel = viewModel
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Regular.subheadline.scaledFont()
            return outgoing
        }
        configuration = updatedConfiguration
        self.buttonEdgeInsets = NSDirectionalEdgeInsets(top: viewModel.verticalInset,
                                                        leading: viewModel.horizontalInset,
                                                        bottom: viewModel.verticalInset,
                                                        trailing: viewModel.horizontalInset)

        accessibilityIdentifier = viewModel.a11yIdentifier

        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)

        layoutIfNeeded()
    }
}
