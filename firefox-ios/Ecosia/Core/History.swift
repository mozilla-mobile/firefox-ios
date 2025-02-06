// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class History {
    public var items: [(Date, Page)] {
        get { dictionary.sorted { $0.0 < $1.0 }.map { ($0.0, $0.1) } }
        set { dictionary = .init(uniqueKeysWithValues: newValue) }
    }

    private(set) var dictionary = [Date: Page]() {
        didSet {
            PageStore.save(history: dictionary)
        }
    }

    public init() {
        dictionary = PageStore.history
    }

    public func add(_ page: Page) {
        dictionary[Date()] = page
    }

    public func delete(_ at: Date) {
        dictionary.removeValue(forKey: at)
    }

    public func deleteAll() {
        dictionary = [:]
    }
}
