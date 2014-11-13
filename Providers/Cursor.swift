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
protocol Cursor : SequenceType {
    typealias ItemType
    var count: Int { get }

    // Extra status information
    var status : CursorStatus { get }
    var statusMessage : String { get }

    // Collection iteration and access functions
    subscript(index: Int) -> ItemType? { get }
    func generate() -> GeneratorOf<ItemType>
}

/*
 * A cursor implementation that wraps an array.
 */
class ArrayCursor<T> : Cursor {
    private let data : [T];
    let status : CursorStatus;
    let statusMessage : String = "";

    var count : Int {
        if (status != CursorStatus.Success) {
            return 0;
        }
        return data.count;
    }
    
    func generate() -> GeneratorOf<T> {
        var nextIndex = 0;
        return GeneratorOf<T>() {
            if (nextIndex >= self.data.count || self.status != CursorStatus.Success) {
                return nil;
            }
            return self.data[nextIndex++];
        }
    }

    init(data: [T], status: CursorStatus, statusMessage: String) {
        self.data = data;
        self.status = status;
        self.statusMessage = statusMessage;
    }
    
    init(data: [T]) {
        self.data = data;
        self.status = CursorStatus.Success;
        self.statusMessage = "Success";
    }
    
    subscript(index: Int) -> T? {
        if (index >= data.count || index < 0 || status != CursorStatus.Success) {
            return nil;
        }
        return data[index];
    }
}
