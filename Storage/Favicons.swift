/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/* The base favicons protocol */
// TODO: Deferred, make this less generic.
public protocol Favicons {
    var defaultIcon: UIImage { get }

    func clear(options: QueryOptions?, complete: ((success: Bool) -> Void)?)
    func get(options: QueryOptions?, complete: (data: Cursor<(Site, Favicon)>) -> Void)
    func add(icon: Favicon, site: Site, complete: ((success: Bool) -> Void)?)
}

// TODO: rip this back out.
public class MockFavicons: Favicons {
    public init() {}

    lazy public var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    public func clear(options: QueryOptions?, complete: ((success: Bool) -> Void)?) {
        if let complete = complete {
            complete(success: false)
        }
    }
    public func get(options: QueryOptions?, complete: (data: Cursor<(Site, Favicon)>) -> Void) {
        complete(data: Cursor())
    }

    public func add(icon: Favicon, site: Site, complete: ((success: Bool) -> Void)?) {
        if let complete = complete {
            complete(success: false)
        }
    }
}
