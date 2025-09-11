// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct ScrollViewCarouselUX {
    static let itemWidthRatio: CGFloat = 0.85
    static let interItemSpacing: CGFloat = 12
    static let swipeAnimation: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.7)
    static let stackSpacing: CGFloat = 0
    static let centerDivisionFactor: CGFloat = 2
    static let selectedAccessibilityPriority = 1.0
    static let unselectedAccessibilityPriority = 0.0
    static let reduceMotionAnimationDuration = 0.3
    static let notificationDelay = 0.3
    static let incrementValue = 1
    static let decrementValue = 1
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
        GeometryReader { geometry in
            scrollViewContent(for: geometry.size)
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
                .onChange(of: scrollPosition, handleScrollPositionChange)
                .onChange(of: selection, handleSelectionChange)
                .accessibilityElement(children: .contain)
                .accessibilityAdjustableAction(handleAccessibilityAdjustment)
                .onAppear {
                    scrollPosition = selection
                }
        }
        .clipped()
    }

    private func itemWidth(for size: CGSize) -> CGFloat {
        size.width * ScrollViewCarouselUX.itemWidthRatio
    }

    private func scrollViewContent(for size: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: ScrollViewCarouselUX.stackSpacing) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    content(item)
                        .frame(width: itemWidth(for: size))
                        .padding(.trailing, index == items.count - 1 ? 0 : ScrollViewCarouselUX.interItemSpacing)
                        .accessibilityElement(children: .contain)
                        .accessibilitySortPriority(
                            index == selection
                            ? ScrollViewCarouselUX.selectedAccessibilityPriority
                            : ScrollViewCarouselUX.unselectedAccessibilityPriority
                        )
                        .accessibilityAddTraits(index == selection ? [.isSelected] : [])
                        .accessibilityHidden(index != selection)
                        .accessibilityScrollAction { edge in
                            switch edge {
                            case .leading: handleDecrementAction()
                            case .trailing: handleIncrementAction()
                            default: break
                            }
                        }
                        .id(index)
                }
            }
            .padding(.horizontal, (size.width - itemWidth(for: size)) / ScrollViewCarouselUX.centerDivisionFactor)
            .scrollTargetLayout()
        }
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
        postScreenChangedNotification()
    }

    private func handleAccessibilityAdjustment(direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: handleIncrementAction()
        case .decrement: handleDecrementAction()
        @unknown default: break
        }
    }

    private func handleIncrementAction() {
        if selection < items.count - ScrollViewCarouselUX.incrementValue {
            selection += ScrollViewCarouselUX.incrementValue
        }
    }

    private func handleDecrementAction() {
        if selection > Int(ScrollViewCarouselUX.unselectedAccessibilityPriority) {
            selection -= ScrollViewCarouselUX.decrementValue
        }
    }

    private func postScreenChangedNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + ScrollViewCarouselUX.notificationDelay) {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    private func provideFeedback() {
        if !reduceMotion {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
