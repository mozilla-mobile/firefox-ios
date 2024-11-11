// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import Foundation
import UIKit

class ContextualHintViewViewController: UIViewController, Themeable {
    private lazy var hintView: ContextualHintView = .build { _ in }
    private struct UX {
        static let contextualHintWidth: CGFloat = 350
        static let contextualHintLandscapeExtraWidth: CGFloat = 60
    }

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()

        var viewModel = ContextualHintViewModel(
            isActionType: true,
            actionButtonTitle: "This button has an action",
            title: "CFR title",
            description: "This contextual hint gives you some context about a random feature",
            arrowDirection: .up,
            closeButtonA11yLabel: "a11yButton",
            actionButtonA11yId: "a11yButtonId"
        )
        viewModel.closeButtonAction = { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        viewModel.actionButtonAction = { [weak self] _ in
            // The action would be done here, now just dismiss the CFR
            self?.dismiss(animated: true, completion: nil)
        }
        hintView.configure(viewModel: viewModel)
        hintView.applyTheme(theme: themeManager.currentTheme)

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: UX.contextualHintWidth, height: UIView.layoutFittingCompressedSize.height)
        var systemSize = hintView.systemLayoutSizeFitting(targetSize)
        if UIDevice.current.orientation.isLandscape {
            systemSize.width += UX.contextualHintLandscapeExtraWidth
        }
        preferredContentSize = systemSize
    }

    // MARK: Themeable

    func applyTheme() {}

    // MARK: View Transitions
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsLayout()
    }
}
