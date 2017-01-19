/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// A token wrapping around a time-based session event for Tiles.
public class OnyxSession {

    /// Session ping to send to the Onyx server
    public var ping: SessionPing?
    
    private var startDate: NSDate?
    
    func start() {
        startDate = NSDate()
    }

    func end() {
        let sessionLength = Int(abs((startDate?.timeIntervalSinceNow ?? 0) * 1000))
        ping?.sessionDuration = sessionLength
    }
}
