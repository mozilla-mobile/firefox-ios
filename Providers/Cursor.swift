/*  This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Status results for a Cursor
 */
enum CursorStatus {
    case Success;
    case Failure;
}

/**
* Provides a generic method of returning some data and status information about a request.
*/
public class Cursor :SequenceType {
    var count: Int {
        get { return 0 }
    }

    // Extra status information
    var status: CursorStatus
    var statusMessage: String

    init(err: NSError) {
        self.status = .Failure
        self.statusMessage = err.description
    }

    init(status: CursorStatus = CursorStatus.Success, msg: String = "") {
        self.status = status
        self.statusMessage = msg
    }

    // Collection iteration and access functions
    subscript(index: Int) -> Any? {
        get { return nil }
    }

    public func generate() -> GeneratorOf<Any> {
        var nextIndex = 0;
        return GeneratorOf<Any>() {
            if (nextIndex >= self.count || self.status != CursorStatus.Success) {
                return nil
            }

            return self[nextIndex++]
        }
    }
}

/*
 * A cursor implementation that wraps an array.
 */
class ArrayCursor<T : Any> : Cursor {
    private let data : [T];

    override var count : Int {
        if (status != CursorStatus.Success) {
            return 0;
        }
        return data.count;
    }

    init(data: [T], status: CursorStatus, statusMessage: String) {
        self.data = data;
        super.init()
        self.status = status;
        self.statusMessage = statusMessage;
    }
    
    init(data: [T]) {
        self.data = data;
        super.init()
        self.status = CursorStatus.Success;
        self.statusMessage = "Success";
    }
    
    override subscript(index: Int) -> Any? {
        get {
            if (index >= data.count || index < 0 || status != CursorStatus.Success) {
                return nil;
            }
            return data[index];
        }
    }
}
