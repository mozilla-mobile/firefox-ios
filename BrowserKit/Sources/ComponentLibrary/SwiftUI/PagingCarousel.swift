// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct PagingCarouselUX {
    static let itemWidthRatio: CGFloat = 0.85
    static let interItemSpacing: CGFloat = 12
    static let scrollAnimationDuration: CGFloat = 0.5
    static let itemAnimationDuration: CGFloat = 0.3
    static let minimumSwipeDistance: CGFloat = 50
    static let edgePaddingAdjustment: CGFloat = 30
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

    @State private var scrollOffset: CGFloat = 0

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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: PagingCarouselUX.interItemSpacing) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            content(item)
                                .frame(width: itemWidth(for: geometry))
                                .animation(
                                    .easeInOut(duration: PagingCarouselUX.itemAnimationDuration),
                                    value: selection
                                )
                                .id(index)
                        }
                    }
                    .padding(.leading, leadingPadding(for: geometry))
                    .padding(.trailing, trailingPadding(for: geometry))
                    .animation(
                        .easeInOut(duration: PagingCarouselUX.scrollAnimationDuration),
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

    /// Calculates item width based on screen size
    private func itemWidth(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width * PagingCarouselUX.itemWidthRatio
    }

    /// Base margin for centering items
    private func baseSideMargin(for geometry: GeometryProxy) -> CGFloat {
        (geometry.size.width - itemWidth(for: geometry)) / 2
    }

    /// Leading padding with edge adjustment
    private func leadingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return isFirstItemSelected ? baseMargin : baseMargin - PagingCarouselUX.edgePaddingAdjustment
    }

    /// Trailing padding with edge adjustment
    private func trailingPadding(for geometry: GeometryProxy) -> CGFloat {
        let baseMargin = baseSideMargin(for: geometry)
        return isLastItemSelected ? baseMargin : baseMargin - PagingCarouselUX.edgePaddingAdjustment
    }

    private var isFirstItemSelected: Bool {
        selection == 0
    }

    private var isLastItemSelected: Bool {
        selection == items.count - 1
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                handleSwipeGesture(with: value.translation)
            }
    }

    /// Scrolls to the currently selected item
    func scrollToSelection(scrollAction: @escaping () -> Void, animated: Bool = false) {
        if animated {
            withAnimation(.easeInOut(duration: PagingCarouselUX.scrollAnimationDuration)) {
                scrollAction()
            }
        } else {
            scrollAction()
        }
    }

    /// Handles swipe gestures for navigation
    private func handleSwipeGesture(with translation: CGSize) {
        let horizontalTranslation = translation.width

        if horizontalTranslation > PagingCarouselUX.minimumSwipeDistance && canNavigateToPrevious {
            selection -= 1
        } else if horizontalTranslation < -PagingCarouselUX.minimumSwipeDistance && canNavigateToNext {
            selection += 1
        }
    }

    private var canNavigateToPrevious: Bool {
        selection > 0
    }

    private var canNavigateToNext: Bool {
        selection < items.count - 1
    }
}
