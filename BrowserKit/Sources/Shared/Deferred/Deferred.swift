//
//  Deferred.swift
//  AsyncNetworkServer
//
//  Created by John Gallagher on 7/19/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation

public let DeferredDefaultQueue = DispatchQueue.global()

// TODO: FXIOS-13184 Remove deferred code or validate it is sendable.
// Also validate the T type is Sendable (actually protected) in all methods.
open class Deferred<T: Sendable>: @unchecked Sendable {
    typealias UponBlock = (DispatchQueue, @Sendable (T) -> ())
    private typealias Protected = (protectedValue: T?, uponBlocks: [UponBlock])

    private var protected: LockProtected<Protected>
    private let defaultQueue: DispatchQueue

    public init(value: T? = nil, defaultQueue: DispatchQueue = DeferredDefaultQueue) {
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
            data.uponBlocks.removeAll(keepingCapacity: false)
            return (data.protectedValue!, blocks)
        }
        for (queue, block) in blocks {
            queue.async { block(filledValue) }
        }
    }

    open func fill(_ value: T) {
        _fill(value: value, assertIfFilled: true)
    }

    public func fillIfUnfilled(_ value: T) {
        _fill(value: value, assertIfFilled: false)
    }

    public func peek() -> T? {
        return protected.withReadLock { $0.protectedValue }
    }

    public func uponQueue(_ queue: DispatchQueue, block: @Sendable @escaping (T) -> ()) {
        let maybeValue: T? = protected.withWriteLock{ data in
            if data.protectedValue == nil {
                data.uponBlocks.append( (queue, block) )
            }
            return data.protectedValue
        }
        if let value = maybeValue {
            queue.async { block(value) }
        }
    }

    public var value: T {
        // fast path - return if already filled
        if let v = peek() {
            return v
        }

        // slow path - block until filled
        let group = DispatchGroup()
        // FIXME: FXIOS-13242 We should not be mutating local context captured in closures. Here we're manually applying
        // some synchronization using a dispatch group.
        nonisolated(unsafe) var result: T!
        group.enter()
        self.upon { result = $0; group.leave() }
        _ = group.wait(timeout: .distantFuture)
        return result
    }

    public func bindQueue<U>(_ queue: DispatchQueue, f: @escaping @Sendable (T) -> Deferred<U>) -> Deferred<U> {
        let d = Deferred<U>()
        self.uponQueue(queue) {
            f($0).uponQueue(queue) {
                d.fill($0)
            }
        }
        return d
    }

    public func mapQueue<U>(_ queue: DispatchQueue, f: @escaping @Sendable (T) -> U) -> Deferred<U> {
        return bindQueue(queue) { t in Deferred<U>(value: f(t)) }
    }

    public func upon(_ block: @Sendable @escaping (T) ->()) {
        uponQueue(defaultQueue, block: block)
    }

    public func bind<U>(_ f: @escaping @Sendable (T) -> Deferred<U>) -> Deferred<U> {
        return bindQueue(defaultQueue, f: f)
    }

    public func map<U>(_ f: @escaping @Sendable (T) -> U) -> Deferred<U> {
        return mapQueue(defaultQueue, f: f)
    }

    public func both<U>(_ other: Deferred<U>) -> Deferred<(T,U)> {
        return self.bind { t in other.map { u in (t, u) } }
    }
}

// FIXME: FXIOS-13242 We want to remove this function for the sake of proper Swift Concurrency
public func all<T>(_ deferreds: [Deferred<T>]) -> Deferred<[T]> {
    if deferreds.count == 0 {
        return Deferred(value: [])
    }

    typealias SendableGenericClosure = @Sendable (T) -> ()

    let combined = Deferred<[T]>()

    // FIXME: FXIOS-13242 We should not be mutating local context captured in closures. For now we're manually applying
    // some synchronization using a dispatch group.
    nonisolated(unsafe) var results: [T] = []
    results.reserveCapacity(deferreds.count)

    DispatchQueue.global(qos: .default).async {
        var iterator = 0
        let group = DispatchGroup()
        let block: SendableGenericClosure = { t in
            results.append(t)
            group.leave()
        }
        while iterator < deferreds.count {
            group.enter()
            deferreds[iterator].upon(block)
            iterator += 1
            group.wait()
        }

        combined.fill(results)
    }

    return combined
}
