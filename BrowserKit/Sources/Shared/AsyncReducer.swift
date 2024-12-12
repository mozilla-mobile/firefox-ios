// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public let DefaultDispatchQueue = DispatchQueue.global()

public func asyncReducer<T, U>(
    _ initialValue: T,
    combine: @escaping (T, U) -> Deferred<Maybe<T>>
) -> AsyncReducer<T, U> {
    return AsyncReducer(initialValue: initialValue, combine: combine)
}

/**
 * A appendable, async `reduce`.
 *
 * The reducer starts empty. New items need to be `append`ed.
 *
 * The constructor takes an `initialValue`, a `dispatch_queue_t`, and a `combine` function.
 *
 * The reduced value can be accessed via the `reducer.terminal` `Deferred<Maybe<T>>`, which is
 * run once all items have been combined.
 *
 * The terminal will never be filled if no items have been appended.
 *
 * Once the terminal has been filled, no more items can be appended, and `append` methods will error.
 */
open class AsyncReducer<T, U> {
    // T is the accumulator. U is the input value. The returned T is the new accumulated value.
    public typealias Combine = (T, U) -> Deferred<Maybe<T>>
    fileprivate let lock = NSRecursiveLock()

    private let dispatchQueue: DispatchQueue
    private let combine: Combine

    private let initialValueDeferred: Deferred<Maybe<T>>
    public let terminal: Deferred<Maybe<T>> = Deferred()

    private var queuedItems: [U] = []

    private var isStarted = false

    /**
     * Has this task queue finished?
     * Once the task queue has finished, it cannot have more tasks appended.
     */
    open var isFilled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return terminal.isFilled
    }

    public convenience init(
        initialValue: T,
        queue: DispatchQueue = DefaultDispatchQueue,
        combine: @escaping Combine
    ) {
        self.init(initialValue: deferMaybe(initialValue), queue: queue, combine: combine)
    }

    public init(
        initialValue: Deferred<Maybe<T>>,
        queue: DispatchQueue = DefaultDispatchQueue,
        combine: @escaping Combine
    ) {
        self.dispatchQueue = queue
        self.combine = combine
        self.initialValueDeferred = initialValue
    }

    // This is always protected by a lock, so we don't need to
    // take another one.
    fileprivate func ensureStarted() {
        if self.isStarted {
            return
        }

        func queueNext(_ deferredValue: Deferred<Maybe<T>>) {
            deferredValue.uponQueue(dispatchQueue, block: continueMaybe)
        }

        func nextItem() -> U? {
            // Because popFirst is only available on array slices.
            // removeFirst is fine for range-replaceable collections.
            return queuedItems.isEmpty ? nil : queuedItems.removeFirst()
        }

        func continueMaybe(_ res: Maybe<T>) {
            lock.lock()
            defer { lock.unlock() }

            if res.isFailure {
                self.queuedItems.removeAll()
                self.terminal.fill(Maybe(failure: res.failureValue!))
                return
            }

            let accumulator = res.successValue!

            guard let item = nextItem() else {
                self.terminal.fill(Maybe(success: accumulator))
                return
            }

            let combineItem = deferDispatchAsync(dispatchQueue) {
                return self.combine(accumulator, item)
            }

            queueNext(combineItem)
        }

        queueNext(self.initialValueDeferred)
        self.isStarted = true
    }

    /**
     * Append one or more tasks onto the end of the queue.
     *
     * @throws AlreadyFilled if the queue has finished already.
     */
    open func append(_ items: U...) throws -> Deferred<Maybe<T>> {
        return try append(items)
    }

    /**
     * Append a list of tasks onto the end of the queue.
     *
     * @throws AlreadyFilled if the queue has already finished.
     */
    open func append(_ items: [U]) throws -> Deferred<Maybe<T>> {
        lock.lock()
        defer { lock.unlock() }

        if terminal.isFilled {
            throw ReducerError.alreadyFilled
        }

        queuedItems.append(contentsOf: items)
        ensureStarted()

        return terminal
    }
}

enum ReducerError: Error {
    case alreadyFilled
}
