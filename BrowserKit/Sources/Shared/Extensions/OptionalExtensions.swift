// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/* A smarter ?? operator which allows the left hand/right hand arguments to not be
 * the same type. This is useful where we want to print the string representation
 * of an optional value that is not a string but want to return a string value when
 * a value is absent.
 *
 * For more informatin, check out Oleb's post:
 * https://oleb.net/blog/2016/12/optionals-string-interpolation/ */

infix operator ???: NilCoalescingPrecedence
public func ??? <T> (optional: T?, defaultValue: @autoclosure () -> String) -> String {
    return optional.map { String(describing: $0) } ?? defaultValue()
}
