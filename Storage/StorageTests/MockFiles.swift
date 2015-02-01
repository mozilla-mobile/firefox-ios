import Foundation
import XCTest

class MockFiles : FileAccessor {
    func getDir(name: String) -> String? {
        let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
        let path = dir?.stringByAppendingPathComponent(name)
        NSFileManager.defaultManager().createDirectoryAtPath(path!, withIntermediateDirectories: false, attributes: nil, error: nil)
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
        return getDir("testing")?.stringByAppendingPathComponent(filename)
    }

    func remove(filename: String) {
        let fileManager = NSFileManager.defaultManager()
        if var file = get(filename) {
            fileManager.removeItemAtPath(file, error: nil)
        }
    }

    func exists(filename: String) -> Bool {
        if var file = get(filename) {
            return NSFileManager.defaultManager().fileExistsAtPath(file)
        }
        return false
    }
}
