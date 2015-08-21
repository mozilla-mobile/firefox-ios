//
//  LockProtected.swift
//  ReadWriteLock
//
//  Created by John Gallagher on 7/17/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation

public final class LockProtected<T> {
    private var lock: ReadWriteLock
    private var item: T

    public convenience init(item: T) {
        self.init(item: item, lock: CASSpinLock())
    }

    public init(item: T, lock: ReadWriteLock) {
        self.item = item
        self.lock = lock
    }

    public func withReadLock<U>(block: T -> U) -> U {
        return lock.withReadLock { [unowned self] in
            return block(self.item)
        }
    }

    public func withWriteLock<U>(block: (inout T) -> U) -> U {
        return lock.withWriteLock { [unowned self] in
            return block(&self.item)
        }
    }
}
