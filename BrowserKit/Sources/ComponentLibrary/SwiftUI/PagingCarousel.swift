// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct PagingCarouselUX {
    static let itemWidthRatio: CGFloat = 0.85
    static let interItemSpacing: CGFloat = 12
    static let scrollAnimationDuration: CGFloat = 0.3
    static let minimumSwipeVelocity: CGFloat = 50
    static let edgePaddingAdjustment: CGFloat = 30
    static let swipeAnimation: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.7)
}

/// A horizontal paging carousel that displays items with smooth scrolling and swipe gestures.
/// Centers the selected item and provides natural navigation between items.
///
/// ## Usage Example
/// ```swift
/// @State private var selectedIndex = 0
/// let items = ["Item 1", "Item 2", "Item 3"]
///
/// PagingCarousel(
///     selection: $selectedIndex,
///     items: items
/// ) { item in
///     Text(item)
///         .frame(maxWidth: .infinity, maxHeight: .infinity)
///         .background(Color.blue)
///         .cornerRadius(12)
/// }
/// ```
public struct PagingCarousel<Item, Content: View>: View {
    @Binding public var selection: Int
    public let items: [Item]
    public let content: (Item) -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var gestureOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

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
            carouselContent(geometry: geometry)
                .gesture(dragGesture(geometry: geometry))
                .animation(PagingCarouselUX.swipeAnimation, value: selection)
                .animation(PagingCarouselUX.swipeAnimation, value: gestureOffset)
                .accessibilityAdjustableAction { direction in
                    handleAccessibilityAdjustment(direction: direction)
                }
                .onChange(of: selection) { _ in
                    postScreenChangedNotification()
                }
        }
        .clipped()
    }

    // MARK: - View Components

    @ViewBuilder
    private func carouselContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: PagingCarouselUX.interItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                carouselItem(index: index, item: item, geometry: geometry)
            }
        }
        .padding(.leading, leadingPadding(for: geometry))
        .padding(.trailing, trailingPadding(for: geometry))
        .offset(x: totalOffset(for: geometry))
    }

    @ViewBuilder
    private func carouselItem(index: Int, item: Item, geometry: GeometryProxy) -> some View {
        content(item)
            .frame(width: itemWidth(for: geometry))
            .accessibilityElement(children: .contain)
            .accessibilitySortPriority(index == selection ? 1 : 0)
            .accessibilityHidden(shouldHideItem(at: index))
            .accessibilityAddTraits(index == selection ? [.isSelected] : [])
            .accessibilityScrollAction { edge in
                switch edge {
                case .leading:
                    handleDecrementAction()
                case .trailing:
                    handleIncrementAction()
                default:
                    break
                }
            }
    }

    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation.width
            }
            .onChanged { _ in
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
                handleDragEnded(value: value, geometry: geometry)
            }
    }

    private func handleAccessibilityAdjustment(direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            handleIncrementAction()
        case .decrement:
            handleDecrementAction()
        @unknown default:
            break
        }
    }

    private func handleIncrementAction() {
        if selection < items.count - 1 {
            selection += 1
            provideFeedback()
            postScreenChangedNotification()
        }
    }

    private func handleDecrementAction() {
        if selection > 0 {
            selection -= 1
            provideFeedback()
            postScreenChangedNotification()
        }
    }

    // MARK: - Layout Calculations

    private func itemWidth(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width * PagingCarouselUX.itemWidthRatio
    }

    private func baseSideMargin(for geometry: GeometryProxy) -> CGFloat {
        (geometry.size.width - itemWidth(for: geometry)) / 2
    }

    private func leadingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return selection == 0 ? baseMargin : baseMargin - PagingCarouselUX.edgePaddingAdjustment
    }

    private func trailingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return selection == items.count - 1 ? baseMargin : baseMargin - PagingCarouselUX.edgePaddingAdjustment
    }

    private func totalOffset(for geometry: GeometryProxy) -> CGFloat {
        let itemFullWidth = itemWidth(for: geometry) + PagingCarouselUX.interItemSpacing
        let baseOffset = -CGFloat(selection) * itemFullWidth

        // Adjust for edge padding changes
        var edgeAdjustment: CGFloat = 0
        if selection > 0 {
            edgeAdjustment += PagingCarouselUX.edgePaddingAdjustment
        }

        return baseOffset + edgeAdjustment + gestureOffset
    }

    // MARK: - Gesture Handling

    private func handleDragEnded(value: DragGesture.Value, geometry: GeometryProxy) {
        let dragThreshold = itemWidth(for: geometry) * 0.3
        let velocity = value.predictedEndTranslation.width - value.translation.width

        // Determine navigation based on drag distance and velocity
        if value.translation.width > dragThreshold || velocity > PagingCarouselUX.minimumSwipeVelocity {
            // Swipe right - go to previous
            if selection > 0 {
                selection -= 1
                provideFeedback()
                postScreenChangedNotification()
            }
        } else if value.translation.width < -dragThreshold || velocity < -PagingCarouselUX.minimumSwipeVelocity {
            // Swipe left - go to next
            if selection < items.count - 1 {
                selection += 1
                provideFeedback()
                postScreenChangedNotification()
            }
        }
        // If neither threshold is met, spring back to current selection
    }

    /// Determines if an item should be hidden from accessibility
    private func shouldHideItem(at index: Int) -> Bool {
        // Only show the currently selected item and adjacent items for better performance
        return index != selection
    }

    /// Forces VoiceOver to refocus on the new content
    private func postScreenChangedNotification() {
        // Delay to ensure the new card is fully rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    /// Provides haptic feedback
    private func provideFeedback() {
        if !reduceMotion {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
