// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol SidebarEnabledViewProtocol: UIView {
    func showSidebar(_ viewController: UIViewController)
    func hideSidebar()
}

class SidebarEnabledView: BaseAlphaStackView, SidebarEnabledViewProtocol {
    private enum UX {
        static let sidebarWidth: CGFloat = 360
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
    func showSidebar(_ viewController: UIViewController) {
        addArrangedSubview(viewController.view)

        NSLayoutConstraint.activate([
            viewController.view.widthAnchor.constraint(equalToConstant: UX.sidebarWidth)
        ])
    }

    func hideSidebar() {
        if arrangedSubviews.count > 1 {
            let view = arrangedSubviews[1]
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
