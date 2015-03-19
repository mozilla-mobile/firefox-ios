/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public protocol FileAccessor {
    func getDir(name: String?, basePath: String?) -> String?
    func get(path: String, basePath: String?) -> String?
    func remove(filename: String, basePath: String?)
    func move(src: String, srcBasePath: String?, dest: String, destBasePath: String?) -> Bool
    func exists(filename: String, basePath: String?) -> Bool
}