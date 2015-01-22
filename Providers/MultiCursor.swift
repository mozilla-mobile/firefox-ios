/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

// @objc required so that we can check for conformance.  i.e. obj is Presenter
// https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html#//apple_ref/doc/uid/TP40014097-CH25-XID_363
@objc protocol Presenter {
    func present(tableView: UITableView) -> UITableViewCell
}

// @objc required so that we can check for conformance. i.e. obj is Loader
// https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Protocols.html#//apple_ref/doc/uid/TP40014097-CH25-XID_363
@objc
protocol Queryable {
    func clearPendingRequests()
    func query(filter: String, callback: () -> Void)
}

class MultiCursor : Cursor, Queryable {
    private var cursors = [Cursor]()
    private var position = -1
    private var positions = [Int]()
    private var currentCursor: Int = 0

    func removeAll() {
        cursors.removeAll(keepCapacity: false)
        positions.removeAll()
        position = -1
        currentCursor = 0
    }

    private func reset() {
        _count = -1

        // Reset everything to initial states
        let p = position
        currentCursor = 0
        position = -1
        for i in 0..<positions.count {
            positions[i] = -1
        }

        // Now walk back up to our current position in the cursor
        // XXX - Is this worth doing?
        while position < p {
            next()
        }
    }

    func addCursor(cursor: Cursor, index: Int? = nil) {
        if let i = index {
            cursors.insert(cursor, atIndex: i)
            positions.insert(-1, atIndex: i)
        } else {
            cursors.append(cursor)
            positions.append(-1)
        }

        reset()
    }

    private var _count = -1
    override var count: Int {
        if _count == -1 {
            _count = 0
            for cursor in cursors {
                _count += cursor.count
            }
        }
        return _count
    }

    private func next() {
        if cursors.count == 0 {
            return
        }

        position++
        for index in currentCursor..<cursors.count {
            let cursor = cursors[index]
            var cursorPosition = positions[index] + 1

            // If this cursor is already all shown, continue
            if cursorPosition >= cursor.count {
                positions[index] = cursor.count
                continue
            }
            positions[index]++

            // If there's something at this cursor for this position, increment it
            if let item = cursor[cursorPosition] {
                currentCursor = index
                return
            }
        }
    }

    private func prev() {
        position--
        for index in reverse(0...currentCursor) {
            let cursor = cursors[index]
            var cursorPosition = positions[index] - 1

            // If this cursor is already all shown, continue
            if cursorPosition < 0 {
                positions[index] = -1;
                continue
            }
            positions[index]--;

            // If there's something at this cursor for this position, increment it
            if let item = cursor[cursorPosition] {
                currentCursor = index;
                return
            }
        }
    }

    // Collection iteration and access functions
    override subscript(index: Int) -> Any? {
        get {
            var c: Any? = nil
            if cursors.count == 0 {
                return c
            }

            while (index < self.position) {
                self.prev()
            }

            while (index > self.position) {
                self.next()
            }

            if (self.currentCursor >= 0 && self.positions[self.currentCursor] >= 0) {
                c = self.cursors[self.currentCursor][self.positions[self.currentCursor]]
            }
            return c
            
        }
    }

    func clearPendingRequests() {
        for cursor in cursors {
            if let q = cursor as? Queryable {
                q.clearPendingRequests()
            }
        }
        reset()
    }

    func query(filter: String, callback: () -> Void) {
        var done = [Bool]()
        for (index, cursor) in enumerate(cursors) {
            done.append(false)

            if let q = cursor as? Queryable {
                q.query(filter) {
                    // For now this calls callback when each cursor returns...
                    self.reset()
                    callback()
                }
            }
        }
    }
}
