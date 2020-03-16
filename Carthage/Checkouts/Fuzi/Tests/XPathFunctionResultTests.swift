// XPathFunctionResultTests.swift
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

class XPathFunctionResultTests: XCTestCase {
  var document: Fuzi.XMLDocument!
  override func setUp() {
    super.setUp()
    let filePath = Bundle(for: AtomTests.self).url(forResource: "atom", withExtension: "xml")!
    do {
      document = try XMLDocument(data: Data(contentsOf: filePath))
    } catch {
      XCTAssertFalse(true, "Error should not be thrown")
    }
    document.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")
  }
  
  func testFunctionResultBoolValue() {
    XCTAssertTrue(document.root!.eval(xpath: "starts-with('Ono','O')")!.boolValue, "Result boolValue should be true")
  }
  
  func testFunctionResultDoubleValue() {
    XCTAssertEqual(document.root!.eval(xpath: "count(./atom:link)")!.doubleValue, 2, "Number of child links should be 2")
  }
  
  func testFunctionResultStringValue() {
    XCTAssertEqual(document.root!.eval(xpath: "string(./atom:entry[1]/dc:language[1]/text())")!.stringValue, "en-us", "Result stringValue should be `en-us`")
  }
}
