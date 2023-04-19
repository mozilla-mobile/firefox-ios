// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

enum ContentType {
    case webview
    case homepage
}

protocol ContentContainable: UIViewController {
    var contentType: ContentType { get }
}

/// A container for view controllers, currently used to embed content in BrowserViewController
class ContentContainer: UIView {
    private var type: ContentType?
    private var contentController: ContentContainable?

    /// Determine if the content can be added, making sure we only add once
    /// - Parameters:
    ///   - viewController: The view controller to add to the container
    /// - Returns: True when we can add the view controller to the container
    func canAdd(content: ContentContainable) -> Bool {
        switch type {
        case .homepage:
            return !(content is HomepageViewController)
        case .webview:
            return !(content is WebviewViewController)
        case .none:
            return true
        }
    }

    /// Add content view controller to the container, we remove the previous content if present before adding new one
    /// - Parameter viewController: The view controller to add
    func add(content: ContentContainable) {
        removePreviousContent()
        saveContentType(content: content)
        addToView(content: content)
    }

    // MARK: - Private

    private func removePreviousContent() {
        contentController?.willMove(toParent: nil)
        contentController?.view.removeFromSuperview()
        contentController?.removeFromParent()
    }

    private func saveContentType(content: ContentContainable) {
        type = content.contentType
        contentController = content
    }

    private func addToView(content: ContentContainable) {
        addSubview(content.view)
        content.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.view.topAnchor.constraint(equalTo: topAnchor),
            content.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
