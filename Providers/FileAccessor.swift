/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol FileAccessor {
    func get(filename: String) -> String?
    func remove(filename: String)
    func move(src: String, dest: String) -> Bool
}

class ProfileFileAccessor : FileAccessor {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    private func getDir() -> String? {
        let basePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let path = basePath.stringByAppendingPathComponent("profile.\(profile.localName())")

        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            var err: NSError? = nil
            if !NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil, error: &err) {
                println("Error creating profile folder at \(path): \(err?.localizedDescription)")
                return nil
            }
        }

        return path
    }

    func move(src: String, dest: String) -> Bool {
        if let f = get(src) {
            if let f2 = get(dest) {
                return NSFileManager.defaultManager().moveItemAtPath(f, toPath: f2, error: nil)
            }
        }

        return false
    }

    func get(filename: String) -> String? {
        return getDir()?.stringByAppendingPathComponent(filename)
    }

    func remove(filename: String) {
        let fileManager = NSFileManager.defaultManager()
        if var file = get(filename) {
            fileManager.removeItemAtPath(file, error: nil)
        }
    }
}
