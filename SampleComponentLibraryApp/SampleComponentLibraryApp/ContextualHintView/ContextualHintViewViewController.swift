// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import Foundation
import UIKit

class ContextualHintViewViewController: UIViewController {
    private lazy var hintView: ContextualHintView = .build { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        var viewModel = ContextualHintViewModel(
            isActionType: true,
            actionButtonTitle: "This button has an action",
            description: "This contextual hint gives you some context about a random feature",
            arrowDirection: .up,
            closeButtonA11yLabel: "a11yButton"
        )
        viewModel.closeButtonAction = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        viewModel.actionButtonAction = { [weak self] _ in
            // The action would be done here, now just dismiss the CFR
            self?.dismiss(animated: true, completion: nil)
        }
        hintView.configure(viewModel: viewModel)

        setupView()
    }

    func configure(anchor: UIView,
                   popOverDelegate: UIPopoverPresentationControllerDelegate) {
        modalPresentationStyle = .popover
        popoverPresentationController?.sourceView = anchor
        popoverPresentationController?.permittedArrowDirections = .up
        popoverPresentationController?.delegate = popOverDelegate
    }

    private func setupView() {
        view.addSubview(hintView)

        NSLayoutConstraint.activate([
            hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hintView.topAnchor.constraint(equalTo: view.topAnchor),
            hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hintView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let themeManager: ThemeManager = AppContainer.shared.resolve()
        hintView.applyTheme(theme: themeManager.currentTheme)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: 350, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = hintView.systemLayoutSizeFitting(targetSize)
    }
}
