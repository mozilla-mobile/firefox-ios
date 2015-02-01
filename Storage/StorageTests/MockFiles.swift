import Foundation
import XCTest

class MockFiles : FileAccessor {
    func getDir(name: String, basePath: String?) -> String? {
        var path = basePath
        if path == nil {
            path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
        }
        return path
    }

    func move(src: String, dest: String) -> Bool {
        if let f = get(src, basePath: nil) {
            if let f2 = get(dest, basePath: nil) {
                return NSFileManager.defaultManager().moveItemAtPath(f, toPath: f2, error: nil)
            }
        }

        return false
    }

    func get(filename: String, basePath: String?) -> String? {
        return getDir("testing", basePath: basePath)?.stringByAppendingPathComponent(filename)
    }

    func remove(filename: String) {
        let fileManager = NSFileManager.defaultManager()
        if var file = get(filename, basePath: nil) {
            fileManager.removeItemAtPath(file, error: nil)
        }
    }

    func exists(filename: String) -> Bool {
        if var file = get(filename, basePath: nil) {
            return NSFileManager.defaultManager().fileExistsAtPath(file)
        }
        return false
    }
}
