// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class OnboardingMultipleChoiceButtonView: UIView, ThemeApplicable {
    struct UX {
        struct Measurements {
            static let padding: CGFloat = 8
        }

        struct Images {
            static let selected = "test"
            static let notSelected = "test"
        }
    }

    // MARK: - Properties
    private var viewModel: OnboardingMultipleChoiceButtonViewModel

    // MARK: - View configuration
    init(with viewModel: OnboardingMultipleChoiceButtonViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
    }

    // MARK: - Actions
    @objc
    func selected() {
    }

    // MARK: - Theme
    public func applyTheme(theme: Theme) {}
}
