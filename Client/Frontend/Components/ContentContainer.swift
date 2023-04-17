// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A container for view controllers, currently used to embed content in BrowserViewController
class ContentContainer: UIView {
    private enum ContentType {
        case webview
        case homepage
    }

    private var type: ContentType?
    private var contentController: UIViewController?

    /// Determine if the content can be added, making sure we only add once
    /// - Parameter viewController: The view controller to add to the container
    /// - Returns: True when we can add the view controller to the container
    func canAdd(viewController: UIViewController) -> Bool {
        switch type {
        case .homepage:
            return !(viewController is HomepageViewController)
        case .webview:
            // FXIOS-6015 - Handle Webview add content
            return true
        case .none:
            return true
        }
    }

    /// Add content view controller to the container, we remove the previous content if present before adding new one
    /// - Parameter viewController: The view controller to add
    func addContent(viewController: UIViewController) {
        removePreviousContent()
        saveContentType(viewController: viewController)
        addToView(viewController: viewController)
    }

    // MARK: - Private

    private func removePreviousContent() {
        contentController?.willMove(toParent: nil)
        contentController?.view.removeFromSuperview()
        contentController?.removeFromParent()
    }

    private func saveContentType(viewController: UIViewController) {
        if viewController is HomepageViewController {
            type = .homepage
        } else {
            // FXIOS-6015 - Handle Webview add content in a else if
            fatalError("Content type not supported")
        }

        contentController = viewController
    }

    private func addToView(viewController: UIViewController) {
        addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
