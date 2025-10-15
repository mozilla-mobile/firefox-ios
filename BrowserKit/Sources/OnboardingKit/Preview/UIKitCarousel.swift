// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit

private struct ScrollViewCarouselUX {
    static let swipeAnimation: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.7)
    static let stackSpacing: CGFloat = 10
    static let reduceMotionAnimationDuration = 0.3
    static let contentMarginHorizontal: CGFloat = 24
    static let containerFrameSpacing: CGFloat = 0
    static let containerFrameCount = 1
    static let containerFrameSpan = 1
}

/// A horizontal scrolling carousel that displays items with smooth scrolling and swipe gestures.
/// Centers the selected item and provides natural navigation between items using UIKit's UIScrollView.
public struct UIKitCarousel<Item, Content: View>: View {
    @Binding public var selection: Int
    public let items: [Item]
    public let content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        selection: Binding<Int>,
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self._selection = selection
        self.items = items
        self.content = content
    }

    public var body: some View {
        CarouselScrollViewRepresentable(
            selection: $selection,
            items: items,
            reduceMotion: reduceMotion,
            content: content
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAdjustableAction { direction in
            handleAccessibilityAdjustment(direction: direction)
        }
    }

    private func handleAccessibilityAdjustment(direction: AccessibilityAdjustmentDirection) {
        let currentIndex = selection
        var newIndex: Int?

        switch direction {
        case .increment:
            if currentIndex < items.count - 1 {
                newIndex = currentIndex + 1
            }
        case .decrement:
            if currentIndex > 0 {
                newIndex = currentIndex - 1
            }
        @unknown default:
            break
        }

        if let newIndex = newIndex {
            selection = newIndex
        }
    }
}

// MARK: - UIViewRepresentable

private struct CarouselScrollViewRepresentable<Item, Content: View>: UIViewRepresentable {
    @Binding var selection: Int
    let items: [Item]
    let reduceMotion: Bool
    let content: (Item) -> Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isPagingEnabled = false
        scrollView.decelerationRate = .fast
        scrollView.delegate = context.coordinator
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear

        context.coordinator.scrollView = scrollView
        context.coordinator.updateContent(items: items, in: scrollView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let coordinator = context.coordinator

        // Update items if changed
        if coordinator.items.count != items.count {
            coordinator.updateContent(items: items, in: scrollView)
        }

        // Scroll to selection if needed
        if coordinator.currentSelection != selection {
            coordinator.currentSelection = selection
            coordinator.scrollToPage(selection, in: scrollView, animated: !reduceMotion)
        }

        coordinator.reduceMotion = reduceMotion
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, items: items, reduceMotion: reduceMotion, content: content)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var selection: Int
        var items: [Item]
        var reduceMotion: Bool
        var currentSelection: Int
        var isUpdatingSelection = false
        weak var scrollView: UIScrollView?
        var hostingControllers: [UIHostingController<AnyView>] = []
        var contentBuilder: (Item) -> Content

        init(selection: Binding<Int>, items: [Item], reduceMotion: Bool, content: @escaping (Item) -> Content) {
            self._selection = selection
            self.items = items
            self.reduceMotion = reduceMotion
            self.currentSelection = selection.wrappedValue
            self.contentBuilder = content
        }

        func updateContent(items: [Item], in scrollView: UIScrollView) {
            self.items = items

            // Remove old hosting controllers
            hostingControllers.forEach { $0.view.removeFromSuperview() }
            hostingControllers.removeAll()

            guard !items.isEmpty else { return }

            // Wait for layout to complete before calculating positions
            DispatchQueue.main.async {
                let scrollViewWidth = scrollView.bounds.width
                let scrollViewHeight = scrollView.bounds.height
                guard scrollViewWidth > 0, scrollViewHeight > 0 else { return }

                let itemWidth = scrollViewWidth - (ScrollViewCarouselUX.contentMarginHorizontal * 2)

                for (index, item) in items.enumerated() {
                    let itemView = self.contentBuilder(item)
                        .frame(width: itemWidth, height: scrollViewHeight)
                    let hostingController = UIHostingController(rootView: AnyView(itemView))
                    hostingController.view.backgroundColor = .clear

                    let xPosition = ScrollViewCarouselUX.contentMarginHorizontal +
                                   (itemWidth + ScrollViewCarouselUX.stackSpacing) * CGFloat(index)

                    hostingController.view.frame = CGRect(
                        x: xPosition,
                        y: 0,
                        width: itemWidth,
                        height: scrollViewHeight
                    )

                    scrollView.addSubview(hostingController.view)
                    self.hostingControllers.append(hostingController)
                }

                // Set content size
                let totalWidth = ScrollViewCarouselUX.contentMarginHorizontal +
                               (itemWidth + ScrollViewCarouselUX.stackSpacing) * CGFloat(items.count) +
                               ScrollViewCarouselUX.contentMarginHorizontal - ScrollViewCarouselUX.stackSpacing
                scrollView.contentSize = CGSize(width: totalWidth, height: scrollViewHeight)

                // Scroll to current selection
                self.scrollToPage(self.currentSelection, in: scrollView, animated: false)
            }
        }

        func scrollToPage(_ page: Int, in scrollView: UIScrollView, animated: Bool) {
            guard page >= 0 && page < items.count else { return }

            let itemWidth = scrollView.bounds.width - (ScrollViewCarouselUX.contentMarginHorizontal * 2)
            let xPosition = (itemWidth + ScrollViewCarouselUX.stackSpacing) * CGFloat(page)

            scrollView.setContentOffset(CGPoint(x: xPosition, y: 0), animated: animated)
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isUpdatingSelection else { return }

            let itemWidth = scrollView.bounds.width - (ScrollViewCarouselUX.contentMarginHorizontal * 2)
            let offset = scrollView.contentOffset.x

            let page = Int(round(offset / (itemWidth + ScrollViewCarouselUX.stackSpacing)))
            let clampedPage = max(0, min(page, items.count - 1))

            if clampedPage != currentSelection {
                currentSelection = clampedPage
                isUpdatingSelection = true
                selection = clampedPage
                provideFeedback()
                isUpdatingSelection = false
            }
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            let itemWidth = scrollView.bounds.width - (ScrollViewCarouselUX.contentMarginHorizontal * 2)
            let itemSpacing = itemWidth + ScrollViewCarouselUX.stackSpacing

            let currentOffset = scrollView.contentOffset.x
            let targetX = targetContentOffset.pointee.x

            // Calculate which page we should snap to
            var targetPage: Int

            if abs(velocity.x) > 0.5 {
                // If there's significant velocity, use velocity-based paging
                targetPage = velocity.x > 0 ? currentSelection + 1 : currentSelection - 1
            } else {
                // For small drags, require at least 30% drag to switch pages
                let dragDistance = currentOffset - (CGFloat(currentSelection) * itemSpacing)
                let dragThreshold = itemWidth * 0.3

                if abs(dragDistance) > dragThreshold {
                    targetPage = dragDistance > 0 ? currentSelection + 1 : currentSelection - 1
                } else {
                    targetPage = currentSelection
                }
            }

            let clampedPage = max(0, min(targetPage, items.count - 1))
            targetContentOffset.pointee.x = CGFloat(clampedPage) * itemSpacing
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                snapToNearestPage(scrollView)
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            snapToNearestPage(scrollView)
        }

        private func snapToNearestPage(_ scrollView: UIScrollView) {
            let itemWidth = scrollView.bounds.width - (ScrollViewCarouselUX.contentMarginHorizontal * 2)
            let itemSpacing = itemWidth + ScrollViewCarouselUX.stackSpacing
            let currentOffset = scrollView.contentOffset.x

            let targetPage = Int(round(currentOffset / itemSpacing))
            let clampedPage = max(0, min(targetPage, items.count - 1))

            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                scrollView.contentOffset.x = CGFloat(clampedPage) * itemSpacing
            }
        }

        private func provideFeedback() {
            if !reduceMotion {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            UIAccessibility.post(notification: .pageScrolled, argument: nil)
        }
    }
}
