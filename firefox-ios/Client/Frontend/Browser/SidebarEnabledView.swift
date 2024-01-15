// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol SidebarEnabledViewProtocol: UIView {
    func showSidebar(_ viewController: UIViewController, parentViewController: UIViewController)
    func hideSidebar(_ parentViewController: UIViewController)
    func updateSidebar(_ viewModel: FakespotViewModel, parentViewController: UIViewController)
}

class SidebarEnabledView: BaseAlphaStackView, SidebarEnabledViewProtocol {
    private enum UX {
        static let sidebarWidth: CGFloat = 360
    }

    var isSidebarVisible: Bool {
        return arrangedSubviews.count > 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        axis = .horizontal
    }

    // MARK: SidebarEnabledViewProtocol
    func showSidebar(_ viewController: UIViewController, parentViewController: UIViewController) {
        guard !isSidebarVisible else { return }

        addArrangedSubview(viewController.view)
        parentViewController.addChild(viewController)
        viewController.didMove(toParent: parentViewController)

        NSLayoutConstraint.activate([
            viewController.view.widthAnchor.constraint(equalToConstant: UX.sidebarWidth)
        ])
    }

    func hideSidebar(_ parentViewController: UIViewController) {
        guard isSidebarVisible,
              let fakespotViewController = parentViewController.children.first(where: { $0 is FakespotViewController })
        else { return }

        fakespotViewController.willMove(toParent: nil)
        fakespotViewController.removeFromParent()
        removeArrangedSubview(fakespotViewController.view)
        fakespotViewController.view.removeFromSuperview()
    }

    func updateSidebar(_ viewModel: FakespotViewModel, parentViewController: UIViewController) {
        guard isSidebarVisible,
              let fakespotViewController = parentViewController.children.first(where: {
                  $0 is FakespotViewController
              }) as? FakespotViewController
        else { return }

        fakespotViewController.update(viewModel: viewModel)
    }
}
