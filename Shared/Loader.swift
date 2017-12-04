/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Interface for listening to Loader updates.
 */
public protocol LoaderListener: class {
    associatedtype T
    func loader(dataLoaded data: T)
}

/**
 * Base implementation for a "push" data model.
 * Interested clients add themselves as listeners for data changes.
 */
open class Loader<T, ListenerType: LoaderListener> where T == ListenerType.T {
    private let listeners = WeakList<ListenerType>()

    public init() {}

    open func addListener(_ listener: ListenerType) {
        listeners.insert(listener)
    }

    open func load(_ data: T) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.listeners.forEach { $0.loader(dataLoaded: data) }
            }
        } else {
            listeners.forEach { $0.loader(dataLoaded: data) }
        }
    }
}
