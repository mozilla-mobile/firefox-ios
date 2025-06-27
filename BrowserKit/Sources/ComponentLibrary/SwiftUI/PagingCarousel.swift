// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A horizontal paging carousel that displays a collection of items with smooth scrolling and gesture support.
///
/// The carousel centers the selected item and provides natural swipe gestures for navigation.
/// Items are displayed with consistent spacing and padding, automatically adjusting for edge cases.
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
    // MARK: - UX Configuration

    /// User experience configuration constants for the carousel
    private let ux = UX()

    private struct UX {
        /// The percentage of screen width each carousel item occupies
        /// Set to 85% to provide comfortable margins and partial visibility of adjacent items
        let itemWidthRatio: CGFloat = 0.85

        /// Standard spacing between carousel items in points
        /// 16pt provides comfortable visual separation without feeling too cramped or spread out
        let interItemSpacing: CGFloat = 12

        /// Animation duration for programmatic scrolling transitions in seconds
        /// 0.5 seconds provides smooth movement that feels natural without being too slow
        let scrollAnimationDuration: CGFloat = 0.5

        /// Animation duration for item appearance changes in seconds
        /// 0.3 seconds for quicker visual feedback on selection changes
        let itemAnimationDuration: CGFloat = 0.3

        /// Minimum swipe distance required to trigger navigation in points
        /// 50pt prevents accidental navigation while allowing easy intentional swipes
        let minimumSwipeDistance: CGFloat = 50

        /// Padding adjustment for edge items in points
        /// 30pt reduction helps maintain visual balance when items are at the edges
        let edgePaddingAdjustment: CGFloat = 30
    }

    // MARK: - Public Properties

    /// Binding to the currently selected item index
    @Binding public var selection: Int

    /// Array of items to display in the carousel
    public let items: [Item]

    /// View builder closure that creates the content view for each item
    public let content: (Item) -> Content

    // MARK: - Private Properties

    /// Tracks the current scroll offset for internal state management
    @State private var scrollOffset: CGFloat = 0

    // MARK: - Initialization

    /// Creates a new paging carousel
    /// - Parameters:
    ///   - selection: Binding to the currently selected item index
    ///   - items: Array of items to display
    ///   - content: ViewBuilder closure that creates the view for each item
    public init(
        selection: Binding<Int>,
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self._selection = selection
        self.items = items
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: ux.interItemSpacing) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            content(item)
                                .frame(width: itemWidth(for: geometry))
                                .animation(
                                    .easeInOut(duration: ux.itemAnimationDuration),
                                    value: selection
                                )
                                .id(index)
                        }
                    }
                    .padding(.leading, leadingPadding(for: geometry))
                    .padding(.trailing, trailingPadding(for: geometry))
                    .animation(
                        .easeInOut(duration: ux.scrollAnimationDuration),
                        value: selection
                    )
                }
                .onAppear {
                    scrollToSelection(scrollAction: {
                        proxy.scrollTo(selection, anchor: .center)
                    })
                }
                .onChange(of: selection) { _ in
                    scrollToSelection(scrollAction: {
                        proxy.scrollTo(selection, anchor: .center)
                    }, animated: true)
                }
                .simultaneousGesture(swipeGesture)
            }
        }
        .clipped()
    }
}

// MARK: - Private Computed Properties

private extension PagingCarousel {
    /// Calculates the width of each carousel item based on the available geometry
    func itemWidth(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width * ux.itemWidthRatio
    }

    /// Calculates the base side margin for centering items
    func baseSideMargin(for geometry: GeometryProxy) -> CGFloat {
        (geometry.size.width - itemWidth(for: geometry)) / 2
    }

    /// Calculates the leading padding, adjusting for edge items
    /// - Parameter geometry: The geometry proxy containing size information
    /// - Returns: The leading padding value
    func leadingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return isFirstItemSelected ? baseMargin : baseMargin - ux.edgePaddingAdjustment
    }

    /// Calculates the trailing padding, adjusting for edge items
    /// - Parameter geometry: The geometry proxy containing size information
    /// - Returns: The trailing padding value
    func trailingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return isLastItemSelected ? baseMargin : baseMargin - ux.edgePaddingAdjustment
    }

    /// Whether the first item is currently selected
    var isFirstItemSelected: Bool {
        selection == 0
    }

    /// Whether the last item is currently selected
    var isLastItemSelected: Bool {
        selection == items.count - 1
    }

    /// Drag gesture for handling swipe navigation
    var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                handleSwipeGesture(with: value.translation)
            }
    }
}

// MARK: - Private Methods

private extension PagingCarousel {
    /// Scrolls to the currently selected item
    /// - Parameters:
    ///   - scrollAction: A closure that performs the scroll action
    ///   - animated: Whether to animate the scroll transition
    func scrollToSelection(scrollAction: @escaping () -> Void, animated: Bool = false) {
        if animated {
            withAnimation(.easeInOut(duration: ux.scrollAnimationDuration)) {
                scrollAction()
            }
        } else {
            scrollAction()
        }
    }

    /// Handles swipe gesture translation and updates selection accordingly
    /// - Parameter translation: The gesture translation containing swipe direction and distance
    func handleSwipeGesture(with translation: CGSize) {
        let horizontalTranslation = translation.width

        // Swipe right (positive translation) - go to previous item
        if horizontalTranslation > ux.minimumSwipeDistance && canNavigateToPrevious {
            selection -= 1
        }
        // Swipe left (negative translation) - go to next item
        else if horizontalTranslation < -ux.minimumSwipeDistance && canNavigateToNext {
            selection += 1
        }
    }

    /// Whether navigation to the previous item is possible
    var canNavigateToPrevious: Bool {
        selection > 0
    }

    /// Whether navigation to the next item is possible
    var canNavigateToNext: Bool {
        selection < items.count - 1
    }
}
