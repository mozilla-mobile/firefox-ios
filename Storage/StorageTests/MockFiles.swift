import Foundation
import XCTest

class MockFiles : FileAccessor {
    func getDir(name: String?, basePath: String? = nil) -> String? {
        var path = basePath
        if path == nil {
            path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
            path?.stringByAppendingPathExtension("testing")
        }

        if let name = name {
            path = path?.stringByAppendingPathExtension(name)
        }

        return path
    }

    func move(src: String, srcBasePath: String? = nil, dest: String, destBasePath: String? = nil) -> Bool {
        if let f = get(src, basePath: srcBasePath) {
            if let f2 = get(dest, basePath: destBasePath) {
                return NSFileManager.defaultManager().moveItemAtPath(f, toPath: f2, error: nil)
            }
        }

        return false
    }

    func get(path: String, basePath: String? = nil) -> String? {
        return getDir(nil, basePath: basePath)?.stringByAppendingPathComponent(path)
    }

    func remove(filename: String, basePath: String? = nil) {
        let fileManager = NSFileManager.defaultManager()
        if var file = get(filename, basePath: nil) {
            fileManager.removeItemAtPath(file, error: nil)
        }
    }

    func exists(filename: String, basePath: String? = nil) -> Bool {
        if var file = get(filename, basePath: nil) {
            return NSFileManager.defaultManager().fileExistsAtPath(file)
        }
        return false
    }
}
