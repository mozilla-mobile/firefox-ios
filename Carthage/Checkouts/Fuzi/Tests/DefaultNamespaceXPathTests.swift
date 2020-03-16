// DefaultNamespaceXPathTests.swift
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

class DefaultNamespaceXPathTests: XCTestCase {
  var document: Fuzi.XMLDocument!
  override func setUp() {
    super.setUp()
    let filePath = Bundle(for: DefaultNamespaceXPathTests.self).url(forResource: "ocf", withExtension: "xml")!
    do {
      document = try XMLDocument(data: Data(contentsOf: filePath))
    } catch {
      XCTAssertFalse(true, "Error should not be thrown")
    }
  }
  
  func testAbsoluteXPathWithDefaultNamespace() {
    document.definePrefix("ocf", forNamespace: "urn:oasis:names:tc:opendocument:xmlns:container")
    let xpath = "/ocf:container/ocf:rootfiles/ocf:rootfile"
    var count = 0
    for element in document.xpath(xpath) {
      XCTAssertEqual("rootfile", element.tag, "tag should be `rootfile`")
      count += 1
    }
    XCTAssertEqual(count, 1, "Element should be found at XPath \(xpath)")
  }
  
  func testRelativeXPathWithDefaultNamespace() {
    document.definePrefix("ocf", forNamespace: "urn:oasis:names:tc:opendocument:xmlns:container")
    let absoluteXPath = "/ocf:container/ocf:rootfiles"
    let relativeXPath = "./ocf:rootfile"
    var count = 0
    for absoluteElement in document.xpath(absoluteXPath) {
      for relativeElement in absoluteElement.xpath(relativeXPath) {
        XCTAssertEqual("rootfile", relativeElement.tag, "tag should be rootfile")
        count += 1
      }
    }
    XCTAssertEqual(count, 1, "Element should be found at XPath '\(relativeXPath)' relative to XPath '\(absoluteXPath)'")
  }
  
  func testDefaultNamespaceInChildNode() {
    document.definePrefix("ocf", forNamespace: "urn:oasis:names:tc:opendocument:xmlns:container")
    document.definePrefix("dc", forNamespace: "http://purl.org/dc/elements/1.1/")
    let results = document.xpath("/ocf:container/dc:metadata/dc:identifier")
    XCTAssertEqual(results.map { $0.rawXML }, ["<identifier id=\"pub-id\">urn:uuid:pubid</identifier>"])
    XCTAssertNil(results.first?.namespace, "The namespace should be empty because none is declared in the document")
  }
}
