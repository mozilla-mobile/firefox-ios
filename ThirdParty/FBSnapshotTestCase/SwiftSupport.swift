/*
*  Copyright (c) 2015, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

public extension FBSnapshotTestCase {
  public func FBSnapshotVerifyView(_ view: UIView, identifier: String = "", suffixes: OrderedSet = FBSnapshotTestCaseDefaultSuffixes(), file: String = #file, line: UInt = #line) {
    FBSnapshotVerifyViewOrLayer(view, identifier: identifier, suffixes: suffixes)
  }

  public func FBSnapshotVerifyLayer(_ layer: CALayer, identifier: String = "", suffixes: OrderedSet = FBSnapshotTestCaseDefaultSuffixes(), file: String = #file, line: UInt = #line) {
    FBSnapshotVerifyViewOrLayer(layer, identifier: identifier, suffixes: suffixes)
  }

  private func FBSnapshotVerifyViewOrLayer(_ viewOrLayer: AnyObject, identifier: String = "", suffixes: OrderedSet = FBSnapshotTestCaseDefaultSuffixes(), file: StaticString = #file, line: UInt = #line) {
    let envReferenceImageDirectory = self.getReferenceImageDirectory(withDefault: FB_REFERENCE_IMAGE_DIR)
    var error: NSError?
    var comparisonSuccess = false

    if let envReferenceImageDirectory = envReferenceImageDirectory {
      for suffix in suffixes {
        let referenceImagesDirectory = "\(envReferenceImageDirectory)\(suffix)"
        if viewOrLayer.isKind(UIView) {
          do {
            try compareSnapshot(of: viewOrLayer as! UIView, referenceImagesDirectory: referenceImagesDirectory, identifier: identifier, tolerance: 0)
            comparisonSuccess = true
          } catch let error1 as NSError {
            error = error1
            comparisonSuccess = false
          }
        } else if viewOrLayer.isKind(CALayer) {
          do {
            try compareSnapshot(of: viewOrLayer as! CALayer, referenceImagesDirectory: referenceImagesDirectory, identifier: identifier, tolerance: 0)
            comparisonSuccess = true
          } catch let error1 as NSError {
            error = error1
            comparisonSuccess = false
          }
        } else {
          assertionFailure("Only UIView and CALayer classes can be snapshotted")
        }

        assert(recordMode == false, message: "Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!", file: file, line: line)

        if comparisonSuccess || recordMode {
          break
        }

        assert(comparisonSuccess, message: "Snapshot comparison failed: \(error)", file: file, line: line)
      }
    } else {
      XCTFail("Missing value for referenceImagesDirectory - Set FB_REFERENCE_IMAGE_DIR as Environment variable in your scheme.")
    }
  }

  func assert(_ assertion: Bool, message: String, file: StaticString, line: UInt) {
    if !assertion {
      XCTFail(message, file: file, line: line)
    }
  }
}
