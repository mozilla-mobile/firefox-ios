//
//  Deferred.swift
//  AsyncNetworkServer
//
//  Created by John Gallagher on 7/19/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation

// TODO: Replace this with a class var
private var DeferredDefaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

public class Deferred<T> {
    typealias UponBlock = (dispatch_queue_t, T -> ())
    private typealias Protected = (protectedValue: T?, uponBlocks: [UponBlock])

    private var protected: LockProtected<Protected>
    private let defaultQueue: dispatch_queue_t

    public init(value: T? = nil, defaultQueue: dispatch_queue_t = DeferredDefaultQueue) {
        protected = LockProtected(item: (value, []))
        self.defaultQueue = defaultQueue
    }

    // Check whether or not the receiver is filled
    public var isFilled: Bool {
        return protected.withReadLock { $0.protectedValue != nil }
    }

    private func _fill(value: T, assertIfFilled: Bool) {
        let (filledValue, blocks) = protected.withWriteLock { data -> (T, [UponBlock]) in
            if assertIfFilled {
                precondition(data.protectedValue == nil, "Cannot fill an already-filled Deferred")
                data.protectedValue = value
            } else if data.protectedValue == nil {
                data.protectedValue = value
            }
            let blocks = data.uponBlocks
            data.uponBlocks.removeAll(keepCapacity: false)
            return (data.protectedValue!, blocks)
        }
        for (queue, block) in blocks {
            dispatch_async(queue) { block(filledValue) }
        }
    }

    public func fill(value: T) {
        _fill(value, assertIfFilled: true)
    }

    public func fillIfUnfilled(value: T) {
        _fill(value, assertIfFilled: false)
    }

    public func peek() -> T? {
        return protected.withReadLock { $0.protectedValue }
    }

    public func uponQueue(queue: dispatch_queue_t, block: T -> ()) {
        let maybeValue: T? = protected.withWriteLock{ data in
            if data.protectedValue == nil {
                data.uponBlocks.append( (queue, block) )
            }
            return data.protectedValue
        }
        if let value = maybeValue {
            dispatch_async(queue) { block(value) }
        }
    }
}

extension Deferred {
    public var value: T {
        // fast path - return if already filled
        if let v = peek() {
            return v
        }

        // slow path - block until filled
        let group = dispatch_group_create()
        var result: T!
        dispatch_group_enter(group)
        self.upon { result = $0; dispatch_group_leave(group) }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        return result
    }
}

extension Deferred {
    public func bindQueue<U>(queue: dispatch_queue_t, f: T -> Deferred<U>) -> Deferred<U> {
        let d = Deferred<U>()
        self.uponQueue(queue) {
            f($0).uponQueue(queue) {
                d.fill($0)
            }
        }
        return d
    }

    public func mapQueue<U>(queue: dispatch_queue_t, f: T -> U) -> Deferred<U> {
        return bindQueue(queue) { t in Deferred<U>(value: f(t)) }
    }
}

extension Deferred {
    public func upon(block: T ->()) {
        uponQueue(defaultQueue, block: block)
    }

    public func bind<U>(f: T -> Deferred<U>) -> Deferred<U> {
        return bindQueue(defaultQueue, f: f)
    }

    public func map<U>(f: T -> U) -> Deferred<U> {
        return mapQueue(defaultQueue, f: f)
    }
}

extension Deferred {
    public func both<U>(other: Deferred<U>) -> Deferred<(T,U)> {
        return self.bind { t in other.map { u in (t, u) } }
    }
}

public func all<T>(deferreds: [Deferred<T>]) -> Deferred<[T]> {
    if deferreds.count == 0 {
        return Deferred(value: [])
    }

    let combined = Deferred<[T]>()
    var results: [T] = []
    results.reserveCapacity(deferreds.count)

    var block: (T -> ())!
    block = { t in
        results.append(t)
        if results.count == deferreds.count {
            combined.fill(results)
        } else {
            deferreds[results.count].upon(block)
        }
    }
    deferreds[0].upon(block)

    return combined
}

public func any<T>(deferreds: [Deferred<T>]) -> Deferred<Deferred<T>> {
    let combined = Deferred<Deferred<T>>()
    for d in deferreds {
        d.upon { _ in combined.fillIfUnfilled(d) }
    }
    return combined
}