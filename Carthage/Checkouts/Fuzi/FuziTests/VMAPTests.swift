// VMAPTests.swift
// Copyright (c) 2015 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
import Fuzi

class VMAPTests: XCTestCase {
  var document: XMLDocument!
  override func setUp() {
    super.setUp()
    let filePath = NSBundle(forClass: VMAPTests.self).pathForResource("vmap", ofType: "xml")!
    do {
      document = try XMLDocument(data: NSData(contentsOfFile: filePath)!)
    } catch {
      XCTAssertFalse(true, "Error should not be thrown")
    }
  }
  
  func testAbsoluteXPathWithNamespace() {
    let xpath = "/vmap:VMAP/vmap:Extensions/uo:unicornOnce"
    var count = 0
    for element in document.xpath(xpath) {
      XCTAssertEqual("unicornOnce", element.tag, "tag should be `unicornOnce`")
      count += 1
    }
    XCTAssertEqual(count, 1, "Element should be found at XPath '\(xpath)'")
  }
  
  func testRelativeXPathWithNamespace() {
   let absoluteXPath = "/vmap:VMAP/vmap:Extensions"
    let relativeXPath = "./uo:unicornOnce"
    var count = 0
    for absoluteElement in document.xpath(absoluteXPath) {
      for relativeElement in absoluteElement.xpath(relativeXPath) {
        XCTAssertEqual("unicornOnce", relativeElement.tag, "tag should be `unicornOnce`")
        count += 1
      }
    }
    XCTAssertEqual(count, 1, "Element should be found at XPath '\(relativeXPath)' relative to XPath '\(absoluteXPath)'");
  }
  
  func testUnicornOnceIsBlank() {
    let xpath = "/vmap:VMAP/vmap:Extensions/uo:unicornOnce"
    let element = document.firstChild(xpath: xpath)
    XCTAssertNotNil(element, "Element should not be nil")
    XCTAssertTrue(element!.isBlank, "Element should be blank")
  }
}
