// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

enum ContentType {
    case webview
    case legacyHomepage
    case privateHomepage
    case nativeErrorPage
    case newHomepage
}

protocol ContentContainable: UIViewController {
    var contentType: ContentType { get }
}

/// A container for view controllers, currently used to embed content in BrowserViewController
class ContentContainer: UIView {
    private var type: ContentType?
    private var contentController: ContentContainable?

    var contentView: UIView? {
        return contentController?.view
    }

    var hasLegacyHomepage: Bool {
        return type == .legacyHomepage
    }

    var hasPrivateHomepage: Bool {
        return type == .privateHomepage
    }

    var hasNewHomepage: Bool {
        return type == .newHomepage
    }

    var hasWebView: Bool {
        return type == .webview
    }

    var hasNativeErrorPage: Bool {
        return type == .nativeErrorPage
    }

    /// Determine if the content can be added, making sure we only add once
    /// - Parameters:
    ///   - viewController: The view controller to add to the container
    /// - Returns: True when we can add the view controller to the container
    func canAdd(content: ContentContainable) -> Bool {
        switch type {
        case .legacyHomepage:
            return !(content is LegacyHomepageViewController)
        case .nativeErrorPage:
            return !(content is NativeErrorPageViewController)
        case .newHomepage:
            return !(content is HomepageViewController)
        case .privateHomepage:
            return !(content is PrivateHomepageViewController)
        case .webview:
            return !(content is WebviewViewController)
        case .none:
            return true
        }
    }

    /// Add content view controller to the container, we remove the previous content if present before adding new one
    /// - Parameter content: The view controller to add
    func add(content: ContentContainable) {
        removePreviousContent()
        saveContentType(content: content)
        addToView(content: content)
    }

    /// Update content in the container. This is used in the case of the webview since
    /// it's not removed, we don't need to add it back again.
    ///
    /// - Parameter content: The content to update
    func update(content: ContentContainable) {
        removePreviousContent()
        saveContentType(content: content)
    }

    // MARK: - Private

    private func removePreviousContent() {
        // Only remove previous content when it's the homepage or native error page.
        // We're not removing the webview controller for now since if it's not loaded, the
        // webview doesn't layout it's WKCompositingView which result in black screen
        guard !hasWebView else { return }
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
