/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class TooltipViewController: UIViewController {

    private lazy var tooltipView: TooltipView = {
        let tooltipView = TooltipView()
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        tooltipView.delegate = self
        return tooltipView
    }()

    public var dismiss: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        preferredContentSize = tooltipView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    private func setupLayout() {
        view.addSubview(tooltipView)
        NSLayoutConstraint.activate([
            tooltipView.topAnchor.constraint(equalTo: view.topAnchor),
            tooltipView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tooltipView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tooltipView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    public func configure(anchoredBy sourceView: UIView, sourceRect: CGRect) {
        modalPresentationStyle = .popover
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceRect
        popoverPresentationController?.permittedArrowDirections = [.up, .down]
        popoverPresentationController?.delegate = self
    }

    public func set(title: String = "", body: String) {
        tooltipView.set(title: title, body: body, maxWidth: .maxWidth)
    }
}

// MARK: - Delegates
extension TooltipViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismiss?()
    }
}

extension TooltipViewController: TooltipViewDelegate {
    public func didTapTooltipDismissButton() {
        dismiss?()
    }
}

fileprivate extension CGFloat {
    static let maxWidth: CGFloat = 220
}
