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
    private let queue = DispatchQueue(label: "GCDReadWriteLock", qos: .default, attributes: .concurrent)

    public init() {}

    public func withReadLock<T>(block: () -> T) -> T {
        var result: T!
        queue.sync() {
            result = block()
        }
        return result
    }

    public func withWriteLock<T>(block: () -> T) -> T {
        var result: T!
        queue.sync {
            result = block()
        }
        return result
    }
}

public class AtomicInt {
    private var mutex = pthread_mutex_t()
    private(set) var value: Int32 = 0

    init() {
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    func compareAndSwap(oldValue: Int32, newValue: Int32) -> Bool {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
        }
        if oldValue != value {
            return false
        }
        value = newValue
        return true
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

    private let _state = AtomicInt()

    public func withWriteLock<T>(block: () -> T) -> T {
        // spin until we acquire write lock
        repeat {
            let state = _state.value

            // if there are no readers and no one holds the write lock, try to grab the write lock immediately
            if (state == 0 || state == Masks.WRITER_WAITING_BIT) &&
                _state.compareAndSwap(oldValue: state, newValue: Masks.WRITER_BIT) {
                    break
            }

            // If we get here, someone is reading or writing. Set the WRITER_WAITING_BIT if
            // it isn't already to block any new readers, then wait a bit before
            // trying again. Ignore CAS failure - we'll just try again next iteration
            if state & Masks.WRITER_WAITING_BIT == 0 {
                _ = _state.compareAndSwap(oldValue: state, newValue: state | Masks.WRITER_WAITING_BIT)
            }
        } while true

        // write lock acquired - run block
        let result = block()

        // unlock
        repeat {
            let state = _state.value

            // clear everything except (possibly) WRITER_WAITING_BIT, which will only be set
            // if another writer is already here and waiting (which will keep out readers)
            if _state.compareAndSwap(oldValue: state, newValue: state & Masks.WRITER_WAITING_BIT) {
                break
            }
        } while true

        return result
    }

    public func withReadLock<T>(block: () -> T) -> T {
        // spin until we acquire read lock
        repeat {
            let state = _state.value

            // if there is no writer and no writer waiting, try to increment reader count
            if (state & Masks.MASK_WRITER_BITS) == 0 &&
                _state.compareAndSwap(oldValue: state, newValue: state + 1) {
                    break
            }
        } while true

        // read lock acquired - run block
        let result = block()

        // decrement reader count
        repeat {
            let state = _state.value

            // sanity check that we have a positive reader count before decrementing it
            assert((state & Masks.MASK_READER_BITS) > 0, "unlocking read lock - invalid reader count")

            // desired new state: 1 fewer reader, preserving whether or not there is a writer waiting
            let newState = ((state & Masks.MASK_READER_BITS) - 1) |
                (state & Masks.WRITER_WAITING_BIT)

            if _state.compareAndSwap(oldValue: state, newValue: newState) {
                break
            }
        } while true

        return result
    }
}
