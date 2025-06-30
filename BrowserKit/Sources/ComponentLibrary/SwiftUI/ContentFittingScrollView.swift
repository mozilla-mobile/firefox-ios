// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A vertically-scrolling container that stretches its content to fill the
/// available width and ensures it’s at least as tall as its parent.
///
/// Usage:
/// ```swift
/// import ComponentLibrary
///
/// struct MyView: View {
///   var body: some View {
///     ContentFittingScrollView {
///       // your content here
///     }
///   }
/// }
/// ```
public struct ContentFittingScrollView<Content: View>: UIViewRepresentable {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = UIColor.clear

        containerView.addSubview(hostingController.view)

        // Store the height constraint for later updates
        let heightConstraint = containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        context.coordinator.containerHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            // Container fills scroll view
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            heightConstraint,

            // Content is centered in container
            hostingController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor)
        ])

        context.coordinator.hostingController = hostingController
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content

        DispatchQueue.main.async {
            guard let hostingView = context.coordinator.hostingController?.view,
                  let heightConstraint = context.coordinator.containerHeightConstraint else { return }

            let contentSize = hostingView.intrinsicContentSize
            let scrollViewSize = scrollView.bounds.size

            // Update container height - use content height if larger than scroll view
            let requiredHeight = max(contentSize.height, scrollViewSize.height)
            heightConstraint.constant = requiredHeight - scrollViewSize.height

            scrollView.bounces = contentSize.height > scrollViewSize.height
            scrollView.isScrollEnabled = contentSize.height > scrollViewSize.height
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        var hostingController: UIHostingController<Content>?
        var scrollView: UIScrollView?
        var containerHeightConstraint: NSLayoutConstraint?  // Added this property
    }
}
