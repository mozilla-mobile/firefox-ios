import Foundation
import XCTest

class MockFiles : FileAccessor {
    private func getDir() -> String? {
        let basePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        return basePath
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

    func exists(filename: String) -> Bool {
        if var file = get(filename) {
            return NSFileManager.defaultManager().fileExistsAtPath(file)
        }
        return false
    }
}
