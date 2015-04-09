import Foundation
import XCTest

class MockFiles: FileAccessor {
    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String
        super.init(rootPath: docPath.stringByAppendingPathComponent("testing"))
    }
}
