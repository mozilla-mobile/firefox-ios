// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

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
/// Centers the selected item and provides natural navigation between items using ScrollView.
@available(iOS 17.0, *)
public struct ScrollViewCarousel<Item, Content: View>: View {
    @Binding public var selection: Int
    public let items: [Item]
    public let content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrollPosition: Int?
    @State private var isInternalUpdate = false

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
        ScrollView(.horizontal, showsIndicators: false) {
            scrollViewContent()
        }
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(
            .horizontal,
            ScrollViewCarouselUX.contentMarginHorizontal,
            for: .scrollContent
        )
        .scrollIndicators(.never)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAdjustableAction { direction in
            handleAccessibilityAdjustment(direction: direction)
        }
        .onChange(of: scrollPosition, handleScrollPositionChange)
        .onChange(of: selection, handleSelectionChange)
        .onAppear {
            scrollPosition = selection
        }
    }

    private func scrollViewContent() -> some View {
        LazyHStack(spacing: ScrollViewCarouselUX.stackSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                content(item)
                    .containerRelativeFrame(
                        .horizontal,
                        count: ScrollViewCarouselUX.containerFrameCount,
                        span: ScrollViewCarouselUX.containerFrameSpan,
                        spacing: ScrollViewCarouselUX.containerFrameSpacing
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityAddTraits(selection == index ? [.isSelected] : [])
                    .accessibilityValue("\(index + 1)")
                    .id(index)
            }
        }
        .scrollTargetLayout()
    }

    private func handleScrollPositionChange(_ oldValue: Int?, _ newPosition: Int?) {
        guard let newPosition = newPosition, newPosition != selection else { return }

        isInternalUpdate = true
        selection = newPosition
        provideFeedback()
        isInternalUpdate = false
    }

    private func handleSelectionChange(_ oldValue: Int, _ newValue: Int) {
        guard !isInternalUpdate else { return }

        withAnimation(
            reduceMotion ? .easeInOut(
                duration: ScrollViewCarouselUX.reduceMotionAnimationDuration
            ) : ScrollViewCarouselUX.swipeAnimation
        ) {
            scrollPosition = newValue
        }
        provideFeedback()
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

    private func provideFeedback() {
        if !reduceMotion {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        // Announce page change for accessibility
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
    }
}
