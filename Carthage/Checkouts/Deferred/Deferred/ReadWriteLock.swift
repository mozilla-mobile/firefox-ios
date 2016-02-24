//
//  ReadWriteLock.swift
//  ReadWriteLock
//
//  Created by John Gallagher on 7/17/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation

public protocol ReadWriteLock: class {
    func withReadLock<T>(block: () -> T) -> T
    func withWriteLock<T>(block: () -> T) -> T
}

public final class GCDReadWriteLock: ReadWriteLock {
    private let queue = dispatch_queue_create("GCDReadWriteLock", DISPATCH_QUEUE_CONCURRENT)

    public init() {}

    public func withReadLock<T>(block: () -> T) -> T {
        var result: T!
        dispatch_sync(queue) {
            result = block()
        }
        return result
    }

    public func withWriteLock<T>(block: () -> T) -> T {
        var result: T!
        dispatch_barrier_sync(queue) {
            result = block()
        }
        return result
    }
}

public final class SpinLock: ReadWriteLock {
    private var lock: UnsafeMutablePointer<Int32>

    public init() {
        lock = UnsafeMutablePointer.alloc(1)
        lock.memory = OS_SPINLOCK_INIT
    }

    deinit {
        lock.dealloc(1)
    }

    public func withReadLock<T>(block: () -> T) -> T {
        OSSpinLockLock(lock)
        let result = block()
        OSSpinLockUnlock(lock)
        return result
    }

    public func withWriteLock<T>(block: () -> T) -> T {
        OSSpinLockLock(lock)
        let result = block()
        OSSpinLockUnlock(lock)
        return result
    }
}

/// Test comment 2
public final class CASSpinLock: ReadWriteLock {
    private struct Masks {
        static let WRITER_BIT: Int32         = 0x40000000
        static let WRITER_WAITING_BIT: Int32 = 0x20000000
        static let MASK_WRITER_BITS          = WRITER_BIT | WRITER_WAITING_BIT
        static let MASK_READER_BITS          = ~MASK_WRITER_BITS
    }

    private var _state: UnsafeMutablePointer<Int32>

    public init() {
        _state = UnsafeMutablePointer.alloc(1)
        _state.memory = 0
    }

    deinit {
        _state.dealloc(1)
    }

    public func withWriteLock<T>(block: () -> T) -> T {
        // spin until we acquire write lock
        repeat {
            let state = _state.memory

            // if there are no readers and no one holds the write lock, try to grab the write lock immediately
            if (state == 0 || state == Masks.WRITER_WAITING_BIT) &&
                OSAtomicCompareAndSwap32Barrier(state, Masks.WRITER_BIT, _state) {
                    break
            }

            // If we get here, someone is reading or writing. Set the WRITER_WAITING_BIT if
            // it isn't already to block any new readers, then wait a bit before
            // trying again. Ignore CAS failure - we'll just try again next iteration
            if state & Masks.WRITER_WAITING_BIT == 0 {
                OSAtomicCompareAndSwap32Barrier(state, state | Masks.WRITER_WAITING_BIT, _state)
            }
        } while true

        // write lock acquired - run block
        let result = block()

        // unlock
        repeat {
            let state = _state.memory

            // clear everything except (possibly) WRITER_WAITING_BIT, which will only be set
            // if another writer is already here and waiting (which will keep out readers)
            if OSAtomicCompareAndSwap32Barrier(state, state & Masks.WRITER_WAITING_BIT, _state) {
                break
            }
        } while true

        return result
    }

    public func withReadLock<T>(block: () -> T) -> T {
        // spin until we acquire read lock
        repeat {
            let state = _state.memory

            // if there is no writer and no writer waiting, try to increment reader count
            if (state & Masks.MASK_WRITER_BITS) == 0 &&
                OSAtomicCompareAndSwap32Barrier(state, state + 1, _state) {
                    break
            }
        } while true

        // read lock acquired - run block
        let result = block()

        // decrement reader count
        repeat {
            let state = _state.memory

            // sanity check that we have a positive reader count before decrementing it
            assert((state & Masks.MASK_READER_BITS) > 0, "unlocking read lock - invalid reader count")

            // desired new state: 1 fewer reader, preserving whether or not there is a writer waiting
            let newState = ((state & Masks.MASK_READER_BITS) - 1) |
                (state & Masks.WRITER_WAITING_BIT)

            if OSAtomicCompareAndSwap32Barrier(state, newState, _state) {
                break
            }
        } while true

        return result
    }
}