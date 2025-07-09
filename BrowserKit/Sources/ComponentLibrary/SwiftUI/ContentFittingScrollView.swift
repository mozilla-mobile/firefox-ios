// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A vertically-scrolling container that stretches its content to fill the
/// available width and ensures it's at least as tall as its parent.
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
        context.coordinator.containerView = containerView

        // Set up Dynamic Type observer
        context.coordinator.setupDynamicTypeObserver()

        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        context.coordinator.updateLayout()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    public class Coordinator {
        var hostingController: UIHostingController<Content>?
        var scrollView: UIScrollView?
        var containerView: UIView?
        var containerHeightConstraint: NSLayoutConstraint?
        private var dynamicTypeObserver: NSObjectProtocol?

        func setupDynamicTypeObserver() {
            // TODO: FXIOS-12794 This is a work around to silence swift 6 warnings about sendability
            let weaklyCapturedClosure = { [weak self] in
                self?.recreateHostingController()
            }
            dynamicTypeObserver = NotificationCenter.default.addObserver(
                forName: UIContentSizeCategory.didChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                // For Dynamic Type changes, we need to completely recreate the hosting controller
                // because SwiftUI views don't always update their intrinsic size properly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    weaklyCapturedClosure()
                }
            }
        }

        private func recreateHostingController() {
            guard let containerView = self.containerView,
                  let oldHostingController = self.hostingController else { return }

            // Remove old hosting controller
            oldHostingController.view.removeFromSuperview()

            // Create new hosting controller with the same content
            let newHostingController = UIHostingController(rootView: oldHostingController.rootView)
            newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            newHostingController.view.backgroundColor = UIColor.clear

            containerView.addSubview(newHostingController.view)

            // Re-establish constraints
            NSLayoutConstraint.activate([
                newHostingController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                newHostingController.view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                newHostingController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor)
            ])

            self.hostingController = newHostingController

            // Now update the layout with the fresh hosting controller
            self.updateLayout()
        }

        func updateLayout() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performLayoutUpdate()
            }
        }

        private func performLayoutUpdate() {
            guard let hostingController = self.hostingController,
                  let scrollView = self.scrollView,
                  let containerView = self.containerView,
                  let heightConstraint = self.containerHeightConstraint else { return }

            self.forceHostingControllerRefresh(hostingController)
            let contentHeight = self.calculateContentHeight(
                hostingView: hostingController.view,
                scrollViewWidth: scrollView.bounds.width
            )

            self.updateScrollViewLayout(
                containerView: containerView,
                heightConstraint: heightConstraint,
                contentHeight: contentHeight,
                scrollViewHeight: scrollView.bounds.height
            )

            self.scheduleDelayedLayoutUpdate(contentHeight: contentHeight)
        }

        private func forceHostingControllerRefresh(_ hostingController: UIHostingController<Content>) {
            let currentContent = hostingController.rootView
            hostingController.rootView = currentContent
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            hostingController.view.invalidateIntrinsicContentSize()
        }

        private func calculateContentHeight(hostingView: UIView, scrollViewWidth: CGFloat) -> CGFloat {
            var contentHeight: CGFloat = 0

            let intrinsicSize = hostingView.intrinsicContentSize
            if intrinsicSize.height > 0 && intrinsicSize.height != UIView.noIntrinsicMetric {
                contentHeight = max(contentHeight, intrinsicSize.height)
            }

            let fittingSize = hostingView.systemLayoutSizeFitting(
                CGSize(width: scrollViewWidth, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            if fittingSize.height > 0 {
                contentHeight = max(contentHeight, fittingSize.height)
            }

            return contentHeight
        }

        private func updateScrollViewLayout(
            containerView: UIView,
            heightConstraint: NSLayoutConstraint,
            contentHeight: CGFloat,
            scrollViewHeight: CGFloat
        ) {
            guard let scrollView = self.scrollView else { return }

            let requiredHeight = max(contentHeight, scrollViewHeight)
            heightConstraint.constant = requiredHeight - scrollViewHeight

            scrollView.bounces = contentHeight > scrollViewHeight
            scrollView.isScrollEnabled = contentHeight > scrollViewHeight

            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
        }

        private func scheduleDelayedLayoutUpdate(contentHeight: CGFloat) {
            guard let hostingView = self.hostingController?.view,
                  let scrollView = self.scrollView,
                  let containerView = self.containerView,
                  let heightConstraint = self.containerHeightConstraint else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let delayedIntrinsicSize = hostingView.intrinsicContentSize
                if delayedIntrinsicSize.height > 0 && delayedIntrinsicSize.height != UIView.noIntrinsicMetric {
                    let finalContentHeight = max(contentHeight, delayedIntrinsicSize.height)
                    self.updateScrollViewLayout(
                        containerView: containerView,
                        heightConstraint: heightConstraint,
                        contentHeight: finalContentHeight,
                        scrollViewHeight: scrollView.bounds.height
                    )
                }
            }
        }
    }
}
