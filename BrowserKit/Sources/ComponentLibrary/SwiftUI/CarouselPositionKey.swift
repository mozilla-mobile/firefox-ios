// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// MARK: - Environment Key for Carousel Position
public struct CarouselPositionKey: EnvironmentKey {
    public static let defaultValue: CarouselPosition? = nil
}

public struct CarouselPosition {
    public let currentIndex: Int
    public let totalItems: Int
    public init(currentIndex: Int, totalItems: Int) {
        self.currentIndex = currentIndex
        self.totalItems = totalItems
    }
}

public extension EnvironmentValues {
    var carouselPosition: CarouselPosition? {
        get { self[CarouselPositionKey.self] }
        set { self[CarouselPositionKey.self] = newValue }
    }
}
