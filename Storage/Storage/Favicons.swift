/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* The base favicons protocol */
public protocol Favicons {
    init(files: FileAccessor)

    func clear(options: QueryOptions?, complete: (success: Bool) -> Void)
    func get(options: QueryOptions?, complete: (data: Cursor) -> Void)
    func add(icon: Favicon, site: Site, complete: (success: Bool) -> Void)
}
