/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MobileCoreServices
import UIKit
import XCTest

class UIPasteboardExtensionsTests: XCTestCase {

    private var pasteboard: UIPasteboard!

    override func setUp() {
        super.setUp()
        pasteboard = UIPasteboard.pasteboardWithUniqueName()
    }

    override func tearDown() {
        super.tearDown()
        UIPasteboard.removePasteboardWithName(pasteboard.name)
    }

    func testAddPNGImage() {
        let path = NSBundle(forClass: self.classForCoder).pathForResource("image", ofType: "png")!
        let data = NSData(contentsOfFile: path)!
        let url = NSURL(string: "http://foo.bar")!
        pasteboard.addImageWithData(data, forURL: url)
        verifyPasteboard(expectedURL: url, expectedImageTypeKey: kUTTypePNG)
    }

    func testAddGIFImage() {
        let path = NSBundle(forClass: self.classForCoder).pathForResource("image", ofType: "gif")!
        let data = NSData(contentsOfFile: path)!
        let url = NSURL(string: "http://foo.bar")!
        pasteboard.addImageWithData(data, forURL: url)
        verifyPasteboard(expectedURL: url, expectedImageTypeKey: kUTTypeGIF)
    }

    private func verifyPasteboard(expectedURL expectedURL: NSURL, expectedImageTypeKey: CFString) {
        XCTAssertEqual(pasteboard.items.count, 1)
        XCTAssertEqual(pasteboard.items[0].count, 2)
        XCTAssertEqual(pasteboard.items[0][kUTTypeURL as String], expectedURL)
        XCTAssertNotNil(pasteboard.items[0][expectedImageTypeKey as String])
    }

}
